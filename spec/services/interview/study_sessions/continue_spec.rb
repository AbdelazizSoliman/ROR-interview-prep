require "rails_helper"

RSpec.describe Interview::StudySessions::Continue do
  it "marks the evaluated question reviewed and returns the next question" do
    session = create(:study_session, question_count: 2)
    first = create(:session_question, study_session: session, position: 0, answered_at: Time.current)
    second = create(:session_question, study_session: session, position: 1)
    attempt = create(:answer_attempt, session_question: first)
    create(:evaluation, answer_attempt: attempt)

    result = described_class.call(study_session: session, session_question: first)

    expect(result.completed).to be(false)
    expect(result.next_session_question).to eq(second)
    expect(first.reload.reviewed_at).to be_present
    expect(session.reload).to be_active
  end

  it "completes only after the final evaluated question is continued" do
    session = create(:study_session, question_count: 1)
    question = create(:session_question, study_session: session, answered_at: Time.current)
    create(:evaluation, answer_attempt: create(:answer_attempt, session_question: question))

    result = described_class.call(study_session: session, session_question: question)

    expect(result.completed).to be(true)
    expect(session.reload).to be_completed
    expect(session.completed_at).to be_present
  end

  it "rejects continuing before evaluation exists" do
    session = create(:study_session, question_count: 1)
    question = create(:session_question, study_session: session, answered_at: Time.current)
    create(:answer_attempt, session_question: question)

    expect { described_class.call(study_session: session, session_question: question) }
      .to raise_error(described_class::InvalidProgression)
    expect(question.reload.reviewed_at).to be_nil
    expect(session.reload).to be_active
  end

  it "is idempotent after a question has already been reviewed" do
    session = create(:study_session, question_count: 1, status: "completed", completed_at: Time.current)
    question = create(:session_question, study_session: session, answered_at: Time.current, reviewed_at: Time.current)

    result = described_class.call(study_session: session, session_question: question)

    expect(result.completed).to be(true)
    expect(question.reload.reviewed_at).to be_present
  end

  it "does not schedule the same question twice" do
    session = create(:study_session, question_count: 1)
    question = create(:session_question, study_session: session, answered_at: Time.current)
    create(:evaluation, answer_attempt: create(:answer_attempt, session_question: question), score: 4)

    described_class.call(study_session: session, session_question: question)
    schedule = ReviewSchedule.find_by!(user: session.user, question: question.question)
    attempts = schedule.attempts_count
    interval = schedule.interval_days
    described_class.call(study_session: session, session_question: question)

    expect(schedule.reload.attempts_count).to eq(attempts)
    expect(schedule.interval_days).to eq(interval)
  end
end
