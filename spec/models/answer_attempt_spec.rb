require "rails_helper"

RSpec.describe AnswerAttempt, type: :model do
  it "requires a session question, nonblank answer, and submission time" do
    attempt = build(:answer_attempt, session_question: nil, answer_text: "  ", submitted_at: nil)

    expect(attempt).not_to be_valid
    expect(attempt.errors.attribute_names).to include(:session_question, :answer_text, :submitted_at)
  end

  it "supports multiple immutable historical attempts for one session question" do
    first = create(:answer_attempt, answer_text: "Initial answer")
    second = create(:answer_attempt, session_question: first.session_question, answer_text: "Future retry")

    expect(first.session_question.reload.answer_attempts).to eq([ first, second ])
    expect(first.session_question.submitted_answer_attempt).to eq(first)
  end

  it "derives question, session, and user from its session question" do
    attempt = create(:answer_attempt)

    expect(attempt.question).to eq(attempt.session_question.question)
    expect(attempt.study_session).to eq(attempt.session_question.study_session)
    expect(attempt.user).to eq(attempt.study_session.user)
  end
end
