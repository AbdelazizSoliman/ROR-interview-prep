FactoryBot.define do
  factory :topic do
    sequence(:name) { |number| "Topic #{number}" }
    sequence(:slug) { |number| "topic-#{number}" }
    position { 0 }
    active { true }
  end
end
