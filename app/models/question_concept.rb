class QuestionConcept < ApplicationRecord
  belongs_to :question

  validates :stable_key, :concept, presence: true
  validates :stable_key, uniqueness: { scope: :question_id }, format: { with: /\A[a-z0-9_]+\z/ }
  validates :weight, numericality: { greater_than: 0 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }

  attr_readonly :stable_key
end
