FactoryBot.define do
  factory :evaluation do
    answer_attempt
    score { 3 }
    summary { "Matched 1 of 1 concepts (Acceptable mid-level answer)." }
    stronger_answer { answer_attempt.question.reference_answer }
    matched_concepts { [] }
    missing_concepts { [] }
    misconceptions { [] }
    evaluator_type { "deterministic" }
    evaluated_at { Time.current }
  end
end
