class QuestionConcept < ApplicationRecord
  belongs_to :question

  validates :concept, presence: true
  validates :weight, numericality: { greater_than: 0 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
end
