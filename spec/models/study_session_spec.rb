require "rails_helper"

RSpec.describe StudySession, type: :model do
  it "accepts the supported session type and statuses" do
    expect(build(:study_session, session_type: "core_mid", status: "active")).to be_valid
    expect(build(:study_session, session_type: "daily_review", status: "active")).to be_valid
    expect(build(:study_session, session_type: "random", status: "active")).not_to be_valid
    expect(build(:study_session, status: "paused")).not_to be_valid
  end

  it "requires a positive question count and a start time" do
    session = build(:study_session, question_count: 0, started_at: nil)

    expect(session).not_to be_valid
    expect(session.errors.attribute_names).to include(:question_count, :started_at)
  end

  it "requires completed_at exactly when completed" do
    expect(build(:study_session, status: "completed", completed_at: nil)).not_to be_valid
    expect(build(:study_session, status: "active", completed_at: Time.current)).not_to be_valid
    expect(build(:study_session, :completed)).to be_valid
  end

  it "returns the first unreviewed session question" do
    session = create(:study_session, question_count: 2)
    answered = create(:session_question, study_session: session, position: 0, answered_at: Time.current, reviewed_at: Time.current)
    current = create(:session_question, study_session: session, position: 1)

    expect(session.current_session_question).to eq(current)
    expect(session.answered_count).to eq(1)
    expect(session.reviewed_count).to eq(1)
    expect(answered).to be_answered_at
  end
end
