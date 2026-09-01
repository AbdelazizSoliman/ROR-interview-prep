FactoryBot.define do
  factory :question do
    topic
    sequence(:stable_key) { |number| "ruby.question_#{number}" }
    sequence(:short_title) { |number| "Question #{number}" }
    prompt { "Explain this Ruby or Rails concept." }
    difficulty { "mid" }
    priority { "core" }
    question_type { "knowledge" }
    reference_answer { "A technically accurate reference answer." }
    active { true }
    position { 0 }
  end
end
