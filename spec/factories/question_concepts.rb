FactoryBot.define do
  factory :question_concept do
    question
    concept { "Core concept" }
    weight { 1 }
    position { 0 }
  end
end
