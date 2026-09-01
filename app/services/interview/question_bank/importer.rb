require "yaml"
require "pathname"
require "set"

module Interview
  module QuestionBank
    class Importer
      class Error < StandardError; end

      Result = Data.define(
        :topics_created,
        :topics_updated,
        :questions_created,
        :questions_updated,
        :concepts_created,
        :concepts_updated,
        :follow_ups_created,
        :follow_ups_updated
      ) do
        def summary
          [
            "Topics: #{topics_created} created, #{topics_updated} updated",
            "Questions: #{questions_created} created, #{questions_updated} updated",
            "Concepts: #{concepts_created} created, #{concepts_updated} updated",
            "Follow-ups: #{follow_ups_created} created, #{follow_ups_updated} updated"
          ].join("\n")
        end
      end

      TOPIC_KEYS = %w[name slug description position active].freeze
      QUESTION_KEYS = %w[
        stable_key topic short_title prompt difficulty priority question_type
        reference_answer explanation common_mistakes active position concepts follow_ups
      ].freeze
      CONCEPT_KEYS = %w[concept explanation weight].freeze
      FOLLOW_UP_KEYS = %w[stable_key relationship_type].freeze

      def self.call(path: Rails.root.join("db/question_bank"))
        new(path:).call
      end

      def initialize(path:)
        @path = Pathname(path)
        @counts = Hash.new(0)
      end

      def call
        source = load_and_validate_source

        ApplicationRecord.transaction do
          topics = import_topics(source.fetch(:topics))
          questions = import_questions(source.fetch(:questions), topics)
          sync_follow_ups(source.fetch(:questions), questions)
        end

        Result.new(**result_counts)
      rescue Psych::Exception => error
        raise Error, "Invalid question-bank YAML: #{error.message}"
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
        raise Error, "Question-bank import failed: #{error.message}"
      end

      private

      attr_reader :path, :counts

      def load_and_validate_source
        files = path.glob("**/*.yml").sort
        raise Error, "No question-bank YAML files found under #{path}" if files.empty?

        topics = {}
        questions = {}

        files.each do |file|
          document = YAML.safe_load_file(file, permitted_classes: [], aliases: false)
          validate_hash!(document, "document in #{file}")
          validate_keys!(document, %w[version topic questions], "document in #{file}")
          require_value!(document, "version", "document in #{file}")
          raise Error, "Unsupported question-bank version in #{file}" unless document["version"] == 1

          topic = validate_topic!(document["topic"], file)
          slug = topic.fetch("slug")
          raise Error, "Duplicate topic slug #{slug.inspect} in source" if topics.key?(slug)

          topics[slug] = topic
          validate_array!(document["questions"], "questions in #{file}")
          document["questions"].each_with_index do |question, index|
            validated = validate_question!(question, topic_slug: slug, context: "question #{index + 1} in #{file}")
            stable_key = validated.fetch("stable_key")
            raise Error, "Duplicate stable_key #{stable_key.inspect} in source" if questions.key?(stable_key)

            questions[stable_key] = validated
          end
        end

        validate_follow_up_graph!(questions)
        { topics:, questions: }
      end

      def validate_topic!(topic, file)
        context = "topic in #{file}"
        validate_hash!(topic, context)
        validate_keys!(topic, TOPIC_KEYS, context)
        %w[name slug position active].each { |key| require_value!(topic, key, context) }
        validate_string!(topic["name"], "name", context)
        validate_string!(topic["slug"], "slug", context)
        validate_optional_string!(topic["description"], "description", context)
        validate_nonnegative_integer!(topic["position"], "position", context)
        validate_boolean!(topic["active"], "active", context)
        topic
      end

      def validate_question!(question, topic_slug:, context:)
        validate_hash!(question, context)
        validate_keys!(question, QUESTION_KEYS, context)
        required = %w[
          stable_key topic prompt difficulty priority question_type reference_answer
          common_mistakes active position concepts
        ]
        required.each { |key| require_value!(question, key, context) }
        %w[stable_key topic prompt reference_answer common_mistakes].each do |key|
          validate_string!(question[key], key, context)
        end
        %w[short_title explanation].each { |key| validate_optional_string!(question[key], key, context) }
        raise Error, "Topic mismatch in #{context}: expected #{topic_slug.inspect}" unless question["topic"] == topic_slug

        validate_allowed!(question["difficulty"], Question::DIFFICULTIES, "difficulty", context)
        validate_allowed!(question["priority"], Question::PRIORITIES, "priority", context)
        validate_allowed!(question["question_type"], Question::TYPES, "question_type", context)
        validate_boolean!(question["active"], "active", context)
        validate_nonnegative_integer!(question["position"], "position", context)
        validate_concepts!(question["concepts"], context)
        validate_follow_ups!(question.fetch("follow_ups", []), context)
        question["follow_ups"] ||= []
        question
      end

      def validate_concepts!(concepts, context)
        validate_array!(concepts, "concepts for #{context}")
        raise Error, "Concepts must not be empty for #{context}" if concepts.empty?

        concepts.each_with_index do |concept, index|
          concept_context = "concept #{index + 1} for #{context}"
          validate_hash!(concept, concept_context)
          validate_keys!(concept, CONCEPT_KEYS, concept_context)
          require_value!(concept, "concept", concept_context)
          validate_string!(concept["concept"], "concept", concept_context)
          validate_optional_string!(concept["explanation"], "explanation", concept_context)
          weight = concept.fetch("weight", 1)
          raise Error, "weight must be positive for #{concept_context}" unless weight.is_a?(Numeric) && weight.positive?
        end
      end

      def validate_follow_ups!(follow_ups, context)
        validate_array!(follow_ups, "follow_ups for #{context}")
        targets = Set.new
        follow_ups.each_with_index do |follow_up, index|
          follow_up_context = "follow-up #{index + 1} for #{context}"
          validate_hash!(follow_up, follow_up_context)
          validate_keys!(follow_up, FOLLOW_UP_KEYS, follow_up_context)
          %w[stable_key relationship_type].each { |key| require_value!(follow_up, key, follow_up_context) }
          validate_string!(follow_up["stable_key"], "stable_key", follow_up_context)
          validate_allowed!(follow_up["relationship_type"], QuestionFollowUp::RELATIONSHIP_TYPES, "relationship_type", follow_up_context)
          raise Error, "Duplicate follow-up target #{follow_up["stable_key"].inspect} for #{context}" unless targets.add?(follow_up["stable_key"])
        end
      end

      def validate_follow_up_graph!(questions)
        questions.each_value do |question|
          question.fetch("follow_ups").each do |follow_up|
            target = follow_up.fetch("stable_key")
            raise Error, "Question #{question.fetch("stable_key")} cannot follow up itself" if target == question.fetch("stable_key")
            raise Error, "Missing follow-up question #{target.inspect} referenced by #{question.fetch("stable_key")}" unless questions.key?(target)
          end
        end
      end

      def import_topics(source_topics)
        source_topics.to_h do |slug, attributes|
          topic = Topic.find_or_initialize_by(slug:)
          new_record = topic.new_record?
          assign_and_save(topic, attributes.slice("name", "description", "position", "active"))
          count_change(:topics, topic, new_record)
          [ slug, topic ]
        end
      end

      def import_questions(source_questions, topics)
        source_questions.to_h do |stable_key, attributes|
          question = Question.find_or_initialize_by(stable_key:)
          new_record = question.new_record?
          assign_and_save(question, question_attributes(attributes).merge(topic: topics.fetch(attributes.fetch("topic"))))
          count_change(:questions, question, new_record)
          sync_concepts(question, attributes.fetch("concepts"))
          [ stable_key, question ]
        end
      end

      def question_attributes(attributes)
        attributes.slice(
          "short_title", "prompt", "difficulty", "priority", "question_type",
          "reference_answer", "explanation", "common_mistakes", "active", "position"
        )
      end

      # Concepts are source-owned and synchronized by array position. Unchanged
      # rows retain identity; changed rows update; surplus rows are removed.
      def sync_concepts(question, desired_concepts)
        existing = question.question_concepts.to_a
        desired_concepts.each_with_index do |attributes, position|
          concept = existing[position] || question.question_concepts.build
          new_record = concept.new_record?
          desired = attributes.slice("concept", "explanation").merge("weight" => attributes.fetch("weight", 1), "position" => position)
          assign_and_save(concept, desired)
          count_change(:concepts, concept, new_record)
        end
        existing.drop(desired_concepts.length).each(&:destroy!)
      end

      def sync_follow_ups(source_questions, questions)
        source_questions.each do |stable_key, attributes|
          question = questions.fetch(stable_key)
          existing = question.question_follow_ups.index_by(&:follow_up_question_id)
          desired_ids = []

          attributes.fetch("follow_ups").each_with_index do |attributes_for_link, position|
            target = questions.fetch(attributes_for_link.fetch("stable_key"))
            desired_ids << target.id
            link = existing[target.id] || question.question_follow_ups.build(follow_up_question: target)
            new_record = link.new_record?
            assign_and_save(link, relationship_type: attributes_for_link.fetch("relationship_type"), position:)
            count_change(:follow_ups, link, new_record)
          end

          question.question_follow_ups.where.not(follow_up_question_id: desired_ids).destroy_all
        end
      end

      def assign_and_save(record, attributes)
        record.assign_attributes(attributes)
        record.save! if record.new_record? || record.changed?
      end

      def count_change(group, record, was_new)
        return counts["#{group}_created".to_sym] += 1 if was_new
        return unless record.saved_changes?

        counts["#{group}_updated".to_sym] += 1
      end

      def result_counts
        Result.members.to_h { |member| [ member, counts[member] ] }
      end

      def validate_hash!(value, context)
        raise Error, "Expected a mapping for #{context}" unless value.is_a?(Hash)
      end

      def validate_array!(value, context)
        raise Error, "Expected a list for #{context}" unless value.is_a?(Array)
      end

      def validate_keys!(value, allowed, context)
        unknown = value.keys - allowed
        raise Error, "Unknown keys #{unknown.join(", ")} in #{context}" if unknown.any?
      end

      def require_value!(value, key, context)
        raise Error, "Missing #{key} in #{context}" unless value.key?(key) && !value[key].nil?
      end

      def validate_string!(value, key, context)
        raise Error, "#{key} must be a non-empty string in #{context}" unless value.is_a?(String) && value.present?
      end

      def validate_optional_string!(value, key, context)
        return if value.nil?

        validate_string!(value, key, context)
      end

      def validate_allowed!(value, allowed, key, context)
        raise Error, "Unknown #{key} #{value.inspect} in #{context}; allowed: #{allowed.join(", ")}" unless allowed.include?(value)
      end

      def validate_nonnegative_integer!(value, key, context)
        raise Error, "#{key} must be a nonnegative integer in #{context}" unless value.is_a?(Integer) && value >= 0
      end

      def validate_boolean!(value, key, context)
        raise Error, "#{key} must be true or false in #{context}" unless value == true || value == false
      end
    end
  end
end
