module Interview
  module ReviewScheduling
    class Update
      Result = Data.define(:review_schedule, :created)

      def self.call(user:, question:, evaluation:)
        new(user:, question:, evaluation:).call
      end

      def initialize(user:, question:, evaluation:)
        @user, @question, @evaluation = user, question, evaluation
      end

      def call
        raise ArgumentError, "Evaluation does not belong to the supplied question" unless evaluation.answer_attempt.question == question

        schedule = user.review_schedules.find_or_initialize_by(question:)
        created = schedule.new_record?
        previous = schedule.attributes
        schedule.attempts_count = schedule.attempts_count.to_i + 1
        schedule.successful_reviews = schedule.successful_reviews.to_i + 1 if evaluation.score >= 3
        schedule.last_score = evaluation.score
        schedule.best_score = [ schedule.best_score || evaluation.score, evaluation.score ].max
        schedule.average_score = (((schedule.average_score.to_d * (schedule.attempts_count - 1)) + evaluation.score) / schedule.attempts_count).round(2)
        result = ScheduleCalculator.call(
          score: evaluation.score,
          attempts_count: schedule.attempts_count,
          successful_reviews: schedule.successful_reviews,
          best_score: schedule.best_score,
          previous_interval_days: previous["interval_days"],
          previous_streak: previous["consecutive_successes"],
          last_score: previous["last_score"]
        )
        schedule.state = result.state
        schedule.consecutive_successes = result.consecutive_successes
        schedule.interval_days = result.interval_days
        schedule.last_reviewed_at = evaluation.evaluated_at
        schedule.next_review_at = evaluation.evaluated_at + result.interval_days.days
        schedule.save!
        Result.new(review_schedule: schedule, created:)
      end

      private

      attr_reader :user, :question, :evaluation
    end
  end
end
