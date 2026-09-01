FactoryBot.define do
  factory :answer_attempt do
    session_question
    answer_text { "My answer from memory." }
    submitted_at { Time.current }
  end
end
