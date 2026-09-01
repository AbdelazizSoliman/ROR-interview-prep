FactoryBot.define do
  factory :session_question do
    study_session
    question
    sequence(:position) { |number| number }
  end
end
