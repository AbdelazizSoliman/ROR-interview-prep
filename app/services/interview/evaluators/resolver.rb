module Interview
  module Evaluators
    module Resolver
      module_function

      def call
        case Configuration.evaluator
        when :deterministic then Deterministic.new
        when :ai then AI.new
        else raise ArgumentError, "Unknown INTERVIEW_EVALUATOR; use deterministic or ai"
        end
      end
    end
  end
end
