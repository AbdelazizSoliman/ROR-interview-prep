require "rails_helper"

RSpec.describe ReviewSchedule, type: :model do
  it "belongs to a user and question with one schedule per pair" do
    schedule = create(:review_schedule)
    duplicate = build(:review_schedule, user: schedule.user, question: schedule.question)

    expect(schedule).to be_valid
    expect(duplicate).not_to be_valid
  end

  it "validates states, counters, and scores" do
    expect(build(:review_schedule, state: "unknown")).not_to be_valid
    expect(build(:review_schedule, attempts_count: -1)).not_to be_valid
    expect(build(:review_schedule, last_score: 6)).not_to be_valid
    expect(build(:review_schedule, average_score: 6)).not_to be_valid
  end
end
