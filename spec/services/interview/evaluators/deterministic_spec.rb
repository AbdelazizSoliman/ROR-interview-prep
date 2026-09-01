require "rails_helper"

RSpec.describe Interview::Evaluators::Deterministic do
  it "matches normalized concept phrases and snapshots missing concepts" do
    question = create(:question, reference_answer: "The reference answer")
    first = create(:question_concept, question:, concept: "Object References", explanation: "Binding", weight: 2)
    second = create(:question_concept, question:, concept: "Mutation", explanation: "State", weight: 1)
    attempt = create(:answer_attempt, session_question: create(:session_question, question:), answer_text: "Object references")

    result = described_class.new.call(question:, answer_attempt: attempt, concepts: [ first, second ])

    expect(result[:score]).to eq(3)
    expect(result[:matched_concepts]).to contain_exactly(hash_including("concept" => "Object References", "weight" => 2.0))
    expect(result[:missing_concepts]).to contain_exactly(hash_including("concept" => "Mutation"))
    expect(result[:misconceptions]).to eq([])
    expect(result[:stronger_answer]).to eq("The reference answer")
  end

  it "returns zero when no concepts match" do
    question = create(:question)
    concept = create(:question_concept, question:, concept: "Transactions")
    attempt = create(:answer_attempt, session_question: create(:session_question, question:), answer_text: "No match")
    result = described_class.new.call(question:, answer_attempt: attempt, concepts: [ concept ])
    expect(result[:score]).to eq(0)
  end
end
