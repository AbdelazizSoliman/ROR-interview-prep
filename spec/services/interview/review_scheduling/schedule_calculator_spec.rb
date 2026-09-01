require "rails_helper"

RSpec.describe Interview::ReviewScheduling::ScheduleCalculator do
  it "uses the documented first-review intervals" do
    expect((0..5).map { |score| described_class.call(score:, attempts_count: 1, successful_reviews: score >= 3 ? 1 : 0, best_score: score, previous_interval_days: 0, previous_streak: 0, last_score: nil).interval_days }).to eq([ 1, 1, 2, 4, 8, 14 ])
  end

  it "grows successful intervals and resets low scores" do
    expect(described_class.call(score: 4, attempts_count: 2, successful_reviews: 2, best_score: 4, previous_interval_days: 8, previous_streak: 1, last_score: 4).interval_days).to eq(16)
    expect(described_class.call(score: 5, attempts_count: 2, successful_reviews: 2, best_score: 5, previous_interval_days: 14, previous_streak: 1, last_score: 4).interval_days).to eq(35)
    expect(described_class.call(score: 1, attempts_count: 2, successful_reviews: 0, best_score: 1, previous_interval_days: 14, previous_streak: 2, last_score: 5).interval_days).to eq(1)
  end

  it "applies the exact state predicates" do
    expect(described_class.call(score: 4, attempts_count: 2, successful_reviews: 2, best_score: 4, previous_interval_days: 8, previous_streak: 1, last_score: 4).state).to eq("strong")
    expect(described_class.call(score: 3, attempts_count: 2, successful_reviews: 2, best_score: 3, previous_interval_days: 4, previous_streak: 0, last_score: 3).state).to eq("reviewing")
    expect(described_class.call(score: 2, attempts_count: 2, successful_reviews: 1, best_score: 4, previous_interval_days: 8, previous_streak: 0, last_score: 2).state).to eq("learning")
    expect(described_class.call(score: 4, attempts_count: 3, successful_reviews: 3, best_score: 4, previous_interval_days: 8, previous_streak: 1, last_score: 4).state).to eq("strong")
    expect(described_class.call(score: 5, attempts_count: 10, successful_reviews: 10, best_score: 5, previous_interval_days: 14, previous_streak: 10, last_score: 5).state).not_to eq("mastered")
  end

  it "resolves representative histories to exactly one Phase 6 state" do
    cases = [
      [ 0, 1, 0, 0, 0, 0, "learning" ],
      [ 5, 1, 1, 5, 0, 5, "learning" ],
      [ 2, 2, 1, 4, 1, 2, "learning" ],
      [ 3, 2, 2, 3, 0, 3, "reviewing" ],
      [ 4, 2, 2, 4, 1, 4, "strong" ],
      [ 3, 2, 2, 5, 1, 3, "reviewing" ],
      [ 2, 3, 2, 5, 0, 2, "reviewing" ]
    ]
    cases.each do |score, attempts, successful, best, streak, last, expected|
      result = described_class.call(score:, attempts_count: attempts, successful_reviews: successful, best_score: best, previous_interval_days: 4, previous_streak: streak, last_score: last)
      expect(%w[learning reviewing strong]).to include(result.state)
      expect(result.state).to eq(expected)
    end
  end
end
