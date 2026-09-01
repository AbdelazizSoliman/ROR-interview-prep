FactoryBot.define do
  factory :question_concept do
    question
    sequence(:stable_key) { |number| "concept_#{number}" }
    concept { "Core concept" }
    weight { 1 }
    position { 0 }
  end
end
