module Interview
  class EvaluateAnswer
    class Error < StandardError; end
    class InvalidResult < Error; end
    class InvalidAnswer < Error; end

    def self.call(answer_attempt:, evaluator: nil)
      new(answer_attempt:, evaluator:).call
    end

    def initialize(answer_attempt:, evaluator:)
      @answer_attempt = answer_attempt
      @evaluator = evaluator || Evaluators::Resolver.call
    end

    def call
      existing = answer_attempt.evaluation
      return existing if existing
      raise InvalidAnswer, "Answer must belong to a submitted session question." unless answer_attempt.session_question.answered_at.present?

      # Hold the row lock through the provider call. This intentionally trades
      # up to the configured network timeout of contention for preventing two
      # simultaneous billable evaluations; no distributed lock is needed here.
      answer_attempt.with_lock do
        existing = answer_attempt.reload.evaluation
        next existing if existing

        normalized = normalize_evaluator_output
        answer_attempt.create_evaluation!(normalized.to_h.merge(evaluated_at: Time.current))
      end
    rescue ActiveRecord::RecordNotUnique
      answer_attempt.reload.evaluation || raise
    end

    private

    attr_reader :answer_attempt, :evaluator

    def normalize_evaluator_output
      raw = evaluator.call(
        question: answer_attempt.question,
        answer_attempt:,
        concepts: answer_attempt.question.question_concepts.ordered
      )
      EvaluationResult.from(raw)
    rescue ArgumentError, KeyError, NoMethodError, TypeError => error
      raise InvalidResult, "Evaluator returned an invalid result: #{error.message}"
    rescue StandardError => error
      raise Error, "Evaluation failed: #{error.message}"
    end
  end
end
