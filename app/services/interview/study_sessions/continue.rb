module Interview
  module StudySessions
    class Continue
      class InvalidProgression < StandardError; end

      Result = Data.define(:next_session_question, :completed)

      def self.call(study_session:, session_question:)
        new(study_session:, session_question:).call
      end

      def initialize(study_session:, session_question:)
        @study_session = study_session
        @session_question = session_question
      end

      def call
        ApplicationRecord.transaction do
          study_session.lock!
          session_question.lock!
          validate_context! unless session_question.reviewed_at.present?
          if session_question.reviewed_at.nil?
            evaluation = session_question.submitted_answer_attempt.evaluation
            ReviewScheduling::Update.call(user: study_session.user, question: session_question.question, evaluation:)
            session_question.update!(reviewed_at: Time.current)
          end
          next_question = study_session.current_session_question
          completed = next_question.nil?
          study_session.update!(status: "completed", completed_at: Time.current) if completed && study_session.active?
          Result.new(next_session_question: next_question, completed:)
        end
      end

      private

      attr_reader :study_session, :session_question

      def validate_context!
        raise InvalidProgression, "This session is no longer active." unless study_session.active?
        raise InvalidProgression, "Question does not belong to this session." unless session_question.study_session_id == study_session.id
        raise InvalidProgression, "Answer the question before continuing." unless session_question.answered_at.present?
        raise InvalidProgression, "Evaluate the answer before continuing." unless session_question.submitted_answer_attempt&.evaluation
        return if study_session.current_session_question == session_question

        raise InvalidProgression, "Questions must be progressed in order."
      end
    end
  end
end
