module Interview
  module StudySessions
    class SubmitAnswer
      class InvalidSubmission < StandardError; end

      Result = Data.define(:answer_attempt, :next_session_question, :completed) do
        def success?
          answer_attempt.persisted?
        end
      end

      def self.call(study_session:, session_question:, answer_text:)
        new(study_session:, session_question:, answer_text:).call
      end

      def initialize(study_session:, session_question:, answer_text:)
        @study_session = study_session
        @session_question = session_question
        @answer_text = answer_text
      end

      def call
        result = nil

        ApplicationRecord.transaction do
          study_session.lock!
          session_question.lock!
          validate_context!

          submitted_at = Time.current
          answer_attempt = session_question.answer_attempts.build(answer_text:, submitted_at:)
          unless answer_attempt.save
            result = Result.new(answer_attempt:, next_session_question: session_question, completed: false)
            raise ActiveRecord::Rollback
          end

          session_question.update!(answered_at: submitted_at)
          next_question = study_session.current_session_question
          completed = next_question.nil?
          study_session.update!(status: "completed", completed_at: submitted_at) if completed
          result = Result.new(answer_attempt:, next_session_question: next_question, completed:)
        end

        result
      rescue ActiveRecord::RecordNotUnique
        raise InvalidSubmission, "This question already has a submitted answer."
      end

      private

      attr_reader :study_session, :session_question, :answer_text

      def validate_context!
        raise InvalidSubmission, "This session is no longer active." unless study_session.active?
        raise InvalidSubmission, "Question does not belong to this session." unless session_question.study_session_id == study_session.id
        raise InvalidSubmission, "This question already has a submitted answer." if session_question.answer_attempts.exists?
        return if study_session.current_session_question == session_question

        raise InvalidSubmission, "Questions must be answered in session order."
      end
    end
  end
end
