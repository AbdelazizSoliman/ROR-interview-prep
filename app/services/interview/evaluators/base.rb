module Interview
  module Evaluators
    class Base
      def call(question:, answer_attempt:, concepts:)
        raise NotImplementedError, "#{self.class} must implement #call"
      end
    end
  end
end
