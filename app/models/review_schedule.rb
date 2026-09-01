class ReviewSchedule < ApplicationRecord
  STATES = %w[unseen learning reviewing strong mastered].freeze

  belongs_to :user
  belongs_to :question

  enum :state, STATES.index_by(&:itself), validate: true

  validates :question_id, uniqueness: { scope: :user_id }
  validates :attempts_count, :successful_reviews, :consecutive_successes, :interval_days,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :last_score, :best_score, numericality: { only_integer: true, in: 0..5 }, allow_nil: true
  validates :average_score, numericality: { in: 0..5 }, allow_nil: true
end
