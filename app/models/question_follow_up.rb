class QuestionFollowUp < ApplicationRecord
  RELATIONSHIP_TYPES = %w[follow_up deeper related].freeze

  belongs_to :question
  belongs_to :follow_up_question, class_name: "Question", inverse_of: :incoming_question_follow_ups

  enum :relationship_type, RELATIONSHIP_TYPES.index_by(&:itself), prefix: :relationship, validate: true

  validates :follow_up_question_id, uniqueness: { scope: :question_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :questions_must_differ

  scope :ordered, -> { order(:position, :id) }

  private

  def questions_must_differ
    return if question_id.blank? || follow_up_question_id.blank? || question_id != follow_up_question_id

    errors.add(:follow_up_question, "must be different from the source question")
  end
end
