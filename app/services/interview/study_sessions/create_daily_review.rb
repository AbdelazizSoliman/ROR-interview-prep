module Interview
  module StudySessions
    class CreateDailyReview
      class NoReviewsDue < StandardError; end
      Result = Data.define(:study_session, :resumed)
      MAX_QUESTIONS = 10

      def self.call(user:)
        new(user:).call
      end

      def initialize(user:)
        @user = user
      end

      def call
        user.with_lock do
          existing = user.study_sessions.active.find_by(session_type: "daily_review")
          return Result.new(study_session: existing, resumed: true) if existing

          now = Time.current
          questions = user.review_schedules
            .joins(:question, question: :topic)
            .where("review_schedules.next_review_at <= ?", now)
            .where(questions: { active: true })
            .order(Arel.sql("review_schedules.next_review_at ASC"), Arel.sql("review_schedules.last_score ASC NULLS FIRST"), Arel.sql("topics.position ASC"), Arel.sql("questions.position ASC"), Arel.sql("questions.stable_key ASC"))
            .limit(MAX_QUESTIONS)
            .map(&:question)
          raise NoReviewsDue, "No reviews are due right now." if questions.empty?

          session = user.study_sessions.create!(session_type: "daily_review", status: "active", question_count: questions.length, started_at: now)
          questions.each_with_index { |question, position| session.session_questions.create!(question:, position:) }
          Result.new(study_session: session, resumed: false)
        end
      end

      private

      attr_reader :user
    end
  end
end
