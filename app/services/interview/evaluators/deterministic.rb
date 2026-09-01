module Interview
  module Evaluators
    class Deterministic < Base
      def call(question:, answer_attempt:, concepts:)
        snapshots = concepts.map { |concept| snapshot(concept) }
        matched, missing = snapshots.partition { |concept| phrase_in_answer?(concept.fetch("concept"), answer_attempt.answer_text) }
        matched_weight = matched.sum { |concept| concept.fetch("weight").to_f }
        total_weight = snapshots.sum { |concept| concept.fetch("weight").to_f }
        score = EvaluationScore.from_coverage(matched_weight:, total_weight:)

        {
          score:,
          summary: "Matched #{matched.length} of #{snapshots.length} concepts (#{EvaluationScore.label(score)}).",
          stronger_answer: question.reference_answer,
          matched_concepts: matched,
          missing_concepts: missing,
          misconceptions: [],
          evaluator_type: "deterministic"
        }
      end

      private

      def snapshot(concept)
        {
          "concept" => concept.concept,
          "explanation" => concept.explanation.to_s,
          "weight" => concept.weight.to_f
        }
      end

      # This deliberately performs phrase matching, not semantic inference. It
      # is a transparent test evaluator; future AI adapters share its output shape.
      def phrase_in_answer?(concept, answer)
        normalize(answer).include?(normalize(concept))
      end

      def normalize(value)
        value.to_s.unicode_normalize(:nfkc).downcase.gsub(/[^a-z0-9]+/, " ").strip
      end
    end
  end
end
