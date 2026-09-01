require "rails_helper"

RSpec.describe Interview::ReviewScheduling::Update do
  it "creates and incrementally updates one schedule" do
    user = create(:user)
    question = create(:question)
    first_attempt = create(:answer_attempt, session_question: create(:session_question, study_session: create(:study_session, user:), question:))
    first = create(:evaluation, answer_attempt: first_attempt, score: 4, evaluated_at: Time.current)
    described_class.call(user:, question:, evaluation: first)
    schedule = ReviewSchedule.find_by!(user:, question:)
    expect(schedule).to have_attributes(attempts_count: 1, successful_reviews: 1, last_score: 4, best_score: 4, interval_days: 8, state: "learning")

    second_session_question = create(:session_question, study_session: create(:study_session, user:, session_type: "daily_review"), question: question, position: 0)
    second_attempt = create(:answer_attempt, session_question: second_session_question)
    second = create(:evaluation, answer_attempt: second_attempt, score: 5, evaluated_at: 1.hour.from_now)
    described_class.call(user:, question:, evaluation: second)
    expect(schedule.reload).to have_attributes(attempts_count: 2, successful_reviews: 2, last_score: 5, best_score: 5, average_score: 4.5, interval_days: 20, state: "strong")
  end
end
