require "rails_helper"

RSpec.describe Interview::StudySessions::SubmitAnswer do
  it "stores the exact answer without advancing" do
    session, first, second = session_with_questions(2)
    text = "  My answer\nwith reasoning.  "

    result = described_class.call(study_session: session, session_question: first, answer_text: text)

    expect(result).to be_success
    expect(second.reload.answered_at).to be_nil
    expect(first.reload.submitted_answer_attempt.answer_text).to eq(text)
    expect(first.answered_at).to eq(first.submitted_answer_attempt.submitted_at)
    expect(session.reload).to be_active
  end

  it "rolls back all state for a blank answer" do
    session, question = session_with_questions(1)

    result = described_class.call(study_session: session, session_question: question, answer_text: " \n ")

    expect(result).not_to be_success
    expect(result.answer_attempt.errors[:answer_text]).to be_present
    expect(question.reload.answered_at).to be_nil
    expect(session.reload).to be_active
    expect(AnswerAttempt.count).to be_zero
  end

  it "does not complete the session when the final answer is only submitted" do
    session, question = session_with_questions(1)

    result = described_class.call(study_session: session, session_question: question, answer_text: "Final answer")

    expect(result).to be_success
    expect(session.reload).to be_active
    expect(question.reload.reviewed_at).to be_nil
  end

  it "rejects duplicate submissions without changing the stored answer" do
    session, question = session_with_questions(1)
    described_class.call(study_session: session, session_question: question, answer_text: "Original answer")

    expect do
      described_class.call(study_session: session, session_question: question, answer_text: "Replacement")
    end.to raise_error(described_class::InvalidSubmission)
    expect(question.reload.submitted_answer_attempt.answer_text).to eq("Original answer")
    expect(question.answer_attempts.count).to eq(1)
  end

  def session_with_questions(count)
    session = create(:study_session, question_count: count)
    questions = count.times.map do |position|
      create(:session_question, study_session: session, position:)
    end
    [ session, *questions ]
  end
end
