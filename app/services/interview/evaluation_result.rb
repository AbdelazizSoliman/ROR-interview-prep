module Interview
  class EvaluationResult
    REQUIRED_ARRAYS = %i[matched_concepts missing_concepts misconceptions].freeze

    attr_reader :score, :summary, :stronger_answer, :matched_concepts,
      :missing_concepts, :misconceptions, :evaluator_type

    def self.from(raw)
      new(raw)
    end

    def initialize(raw)
      data = raw.to_h.symbolize_keys
      @score = data.fetch(:score)
      @summary = data.fetch(:summary)
      @stronger_answer = data.fetch(:stronger_answer)
      @matched_concepts = data.fetch(:matched_concepts)
      @missing_concepts = data.fetch(:missing_concepts)
      @misconceptions = data.fetch(:misconceptions)
      @evaluator_type = data.fetch(:evaluator_type)
      validate!
    rescue KeyError, NoMethodError, TypeError => error
      raise ArgumentError, "Evaluator result has an invalid shape: #{error.message}"
    end

    def to_h
      { score:, summary:, stronger_answer:, matched_concepts:, missing_concepts:, misconceptions:, evaluator_type: }
    end

    private

    def validate!
      raise ArgumentError, "score must be an integer from 0 to 5" unless score.is_a?(Integer) && score.between?(0, 5)
      raise ArgumentError, "summary must be a string" unless summary.nil? || summary.is_a?(String)
      raise ArgumentError, "stronger_answer must be a non-empty string" unless stronger_answer.is_a?(String) && stronger_answer.present?
      raise ArgumentError, "evaluator_type must be a non-empty string" unless evaluator_type.is_a?(String) && evaluator_type.present?
      REQUIRED_ARRAYS.each do |field|
        value = public_send(field)
        raise ArgumentError, "#{field} must be an array" unless value.is_a?(Array)
      end
      [ matched_concepts, missing_concepts ].each { |entries| entries.each { |entry| validate_concept_snapshot!(entry) } }
      misconceptions.each do |entry|
        raise ArgumentError, "misconceptions entries must contain statement and explanation" unless entry.is_a?(Hash) && entry["statement"].is_a?(String) && entry["explanation"].is_a?(String)
      end
    end

    def validate_concept_snapshot!(entry)
      valid = entry.is_a?(Hash) && entry["concept"].is_a?(String) && entry["explanation"].is_a?(String) && entry["weight"].is_a?(Numeric)
      raise ArgumentError, "concept entries must contain concept, explanation, and weight" unless valid
    end
  end
end
