module Interview
  module ReviewScheduling
    class ScheduleCalculator
      Result = Data.define(:interval_days, :consecutive_successes, :state)
      BASE_INTERVALS = { 0 => 1, 1 => 1, 2 => 2, 3 => 4, 4 => 8, 5 => 14 }.freeze

      def self.call(score:, attempts_count:, successful_reviews:, best_score:, previous_interval_days: 0, previous_streak: 0, last_score: nil)
        new(score:, attempts_count:, successful_reviews:, best_score:, previous_interval_days:, previous_streak:, last_score:).call
      end

      def initialize(score:, attempts_count:, successful_reviews:, best_score:, previous_interval_days:, previous_streak:, last_score:)
        @score, @attempts_count, @successful_reviews, @best_score = score, attempts_count, successful_reviews, best_score
        @previous_interval_days, @previous_streak, @last_score = previous_interval_days, previous_streak, last_score
      end

      def call
        streak = score >= 4 ? previous_streak + 1 : (score == 3 ? previous_streak : 0)
        interval = if previous_interval_days.to_i.zero?
          BASE_INTERVALS.fetch(score)
        elsif score <= 1
          1
        elsif score == 2
          2
        elsif score == 3
          [ 4, (previous_interval_days * 1.5).ceil ].max
        elsif score == 4
          [ 8, (previous_interval_days * 2).ceil ].max
        else
          [ 14, (previous_interval_days * 2.5).ceil ].max
        end
        Result.new(interval_days: interval, consecutive_successes: streak, state: state_for(streak:))
      end

      private

      attr_reader :score, :attempts_count, :successful_reviews, :best_score, :previous_interval_days, :previous_streak, :last_score

      def state_for(streak:)
        return "strong" if streak >= 2 && score >= 4
        return "reviewing" if attempts_count >= 2 && successful_reviews >= 2

        "learning"
      end
    end
  end
end
