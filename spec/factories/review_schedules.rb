FactoryBot.define do
  factory :review_schedule do
    user
    question
    state { "learning" }
    attempts_count { 1 }
    successful_reviews { 0 }
    last_score { 2 }
    best_score { 2 }
    average_score { 2 }
    consecutive_successes { 0 }
    interval_days { 2 }
    last_reviewed_at { Time.current }
    next_review_at { 1.day.from_now }
  end
end
