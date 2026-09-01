class Question < ApplicationRecord
  DIFFICULTIES = %w[junior mid strong_mid senior].freeze
  PRIORITIES = %w[core important advanced].freeze
  TYPES = %w[knowledge comparison debugging production_scenario architecture code_reasoning sql].freeze

  belongs_to :topic
  has_many :question_concepts, -> { order(:position, :id) }, dependent: :destroy
  has_many :question_follow_ups, -> { order(:position, :id) }, dependent: :destroy
  has_many :follow_up_questions, through: :question_follow_ups
  has_many :incoming_question_follow_ups,
    class_name: "QuestionFollowUp",
    foreign_key: :follow_up_question_id,
    inverse_of: :follow_up_question,
    dependent: :destroy
  has_many :session_questions, dependent: :restrict_with_exception

  enum :difficulty, DIFFICULTIES.index_by(&:itself), validate: true
  enum :priority, PRIORITIES.index_by(&:itself), validate: true
  enum :question_type, TYPES.index_by(&:itself), validate: true

  validates :stable_key, :prompt, :reference_answer, presence: true
  validates :stable_key, uniqueness: true, format: { with: /\A[a-z0-9_]+(?:\.[a-z0-9_]+)+\z/ }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  attr_readonly :stable_key

  scope :ordered, -> { order(:position, :id) }
  scope :active, -> { where(active: true) }
end
