require "rails_helper"

RSpec.describe Interview::StudySessions::CreateDailyReview do
  let(:user) { create(:user) }

  it "selects only due active questions in deterministic order" do
    old = create(:question, position: 1)
    weak = create(:question, position: 0)
    future = create(:question)
    inactive = create(:question, active: false)
    due_at = 2.days.ago
    create(:review_schedule, user:, question: old, next_review_at: due_at, last_score: 4)
    create(:review_schedule, user:, question: weak, next_review_at: due_at, last_score: 1)
    create(:review_schedule, user:, question: future, next_review_at: 1.day.from_now)
    create(:review_schedule, user:, question: inactive, next_review_at: 2.days.ago)

    session = described_class.call(user:).study_session

    expect(session.session_type).to eq("daily_review")
    expect(session.session_questions.map(&:question)).to eq([ weak, old ])
  end

  it "resumes an active daily review and rejects an empty queue" do
    expect { described_class.call(user:) }.to raise_error(described_class::NoReviewsDue)
    question = create(:question)
    create(:review_schedule, user:, question:, next_review_at: 1.day.ago)
    first = described_class.call(user:).study_session
    result = described_class.call(user:)
    expect(result.study_session).to eq(first)
    expect(result.resumed).to be(true)
    expect(user.study_sessions.where(session_type: "daily_review").count).to eq(1)
  end
end
