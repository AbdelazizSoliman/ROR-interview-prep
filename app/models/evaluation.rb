class Evaluation < ApplicationRecord
  belongs_to :answer_attempt

  validates :score, inclusion: { in: 0..5 }
  validates :answer_attempt_id, uniqueness: true
  validates :stronger_answer, :evaluator_type, :evaluated_at, presence: true
  validates :evaluator_model, length: { maximum: 255 }, allow_nil: true
  validate :feedback_fields_are_arrays

  attr_readonly :score, :summary, :stronger_answer,
    :matched_concepts, :missing_concepts, :misconceptions, :evaluator_type, :evaluator_model, :evaluated_at

  private

  def feedback_fields_are_arrays
    %i[matched_concepts missing_concepts misconceptions].each do |field|
      errors.add(field, "must be an array") unless public_send(field).is_a?(Array)
    end
  end
end
