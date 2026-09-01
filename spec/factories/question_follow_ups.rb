FactoryBot.define do
  factory :question_follow_up do
    question
    association :follow_up_question, factory: :question
    relationship_type { "follow_up" }
    position { 0 }
  end
end
