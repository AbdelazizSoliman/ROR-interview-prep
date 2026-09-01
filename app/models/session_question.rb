class SessionQuestion < ApplicationRecord
  belongs_to :study_session
  belongs_to :question
  has_many :answer_attempts, -> { order(:submitted_at, :created_at, :id) }, dependent: :destroy

  validates :question_id, uniqueness: { scope: :study_session_id }
  validates :position, uniqueness: { scope: :study_session_id }, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  delegate :user, to: :study_session

  # Phase 3 submits once through the application flow. The earliest attempt is
  # the original answer shown when revisiting an answered question; later phases
  # may append retry attempts without changing this historical response.
  def submitted_answer_attempt
    answer_attempts.first
  end

  scope :ordered, -> { order(:position, :id) }
  scope :unanswered, -> { where(answered_at: nil) }
end
