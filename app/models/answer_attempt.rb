class AnswerAttempt < ApplicationRecord
  belongs_to :session_question

  validates :answer_text, :submitted_at, presence: true

  attr_readonly :session_question_id, :answer_text, :submitted_at

  delegate :study_session, :question, :user, to: :session_question
end
