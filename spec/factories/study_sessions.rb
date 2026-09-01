FactoryBot.define do
  factory :study_session do
    user
    session_type { "core_mid" }
    status { "active" }
    question_count { 1 }
    started_at { Time.current }

    trait :completed do
      status { "completed" }
      completed_at { Time.current }
    end
  end
end
