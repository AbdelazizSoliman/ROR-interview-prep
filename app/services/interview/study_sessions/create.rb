module Interview
  module StudySessions
    class Create
      class NoQuestionsAvailable < StandardError; end

      Result = Data.define(:study_session, :resumed)

      MAX_QUESTIONS = 10

      def self.call(user:, session_type: "core_mid")
        return CreateDailyReview.call(user:) if session_type.to_s == "daily_review"

        new(user:, session_type:).call
      end

      def initialize(user:, session_type:)
        @user = user
        @session_type = session_type
      end

      def call
        user.with_lock do
          existing = user.study_sessions.active.find_by(session_type:)
          return Result.new(study_session: existing, resumed: true) if existing

          questions = eligible_questions.to_a
          raise NoQuestionsAvailable, "No Core Mid-Level questions are available yet." if questions.empty?

          study_session = user.study_sessions.create!(
            session_type:,
            status: "active",
            question_count: questions.length,
            started_at: Time.current
          )
          questions.each_with_index do |question, position|
            study_session.session_questions.create!(question:, position:)
          end

          Result.new(study_session:, resumed: false)
        end
      end

      private

      attr_reader :user, :session_type

      def eligible_questions
        Question
          .joins(:topic)
          .where(active: true, priority: "core", difficulty: %w[mid strong_mid])
          .order("topics.position ASC", "questions.position ASC", "questions.stable_key ASC")
          .limit(MAX_QUESTIONS)
      end
    end
  end
end
