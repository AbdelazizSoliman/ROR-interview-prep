class StudySession < ApplicationRecord
  SESSION_TYPES = %w[core_mid].freeze
  STATUSES = %w[active completed abandoned].freeze

  belongs_to :user
  has_many :session_questions, -> { order(:position, :id) }, dependent: :destroy
  has_many :questions, through: :session_questions
  has_many :answer_attempts, through: :session_questions

  enum :session_type, SESSION_TYPES.index_by(&:itself), validate: true
  enum :status, STATUSES.index_by(&:itself), validate: true

  validates :question_count, numericality: { only_integer: true, greater_than: 0 }
  validates :started_at, presence: true
  validate :completed_at_matches_status

  def current_session_question
    session_questions.find_by(answered_at: nil)
  end

  def answered_count
    session_questions.where.not(answered_at: nil).count
  end

  private

  def completed_at_matches_status
    if completed? && completed_at.blank?
      errors.add(:completed_at, "must be present for a completed session")
    elsif !completed? && completed_at.present?
      errors.add(:completed_at, "must only be set for a completed session")
    end
  end
end
