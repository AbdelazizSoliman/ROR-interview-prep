require "rails_helper"

RSpec.describe Interview::EvaluateAnswer do
  it "creates an evaluation once and returns it on repeat calls" do
    question = create(:question, reference_answer: "Reference")
    create(:question_concept, question:, concept: "Ruby")
    session_question = create(:session_question, question:, answered_at: Time.current)
    attempt = create(:answer_attempt, session_question:, answer_text: "Ruby")

    first = described_class.call(answer_attempt: attempt)
    second = described_class.call(answer_attempt: attempt)

    expect(first).to eq(second)
    expect(attempt.reload.evaluation).to eq(first)
    expect(Evaluation.where(answer_attempt: attempt).count).to eq(1)
  end

  it "persists the selected evaluator model metadata" do
    session_question = create(:session_question, answered_at: Time.current)
    attempt = create(:answer_attempt, session_question:)
    evaluator = lambda do |**|
      {
        score: 3, summary: "Good", stronger_answer: "Reference",
        matched_concepts: [], missing_concepts: [], misconceptions: [],
        evaluator_type: "openai", evaluator_model: "gpt-test"
      }
    end

    evaluation = described_class.call(answer_attempt: attempt, evaluator:)

    expect(evaluation.evaluator_type).to eq("openai")
    expect(evaluation.evaluator_model).to eq("gpt-test")
  end

  it "rejects malformed evaluator output without persisting" do
    session_question = create(:session_question, answered_at: Time.current)
    attempt = create(:answer_attempt, session_question:)
    evaluator = ->(**) { { score: 9 } }

    expect { described_class.call(answer_attempt: attempt, evaluator:) }.to raise_error(Interview::EvaluateAnswer::InvalidResult)
    expect(attempt.reload.evaluation).to be_nil
  end

  it "preserves the immutable answer when evaluation fails" do
    session_question = create(:session_question, answered_at: Time.current)
    attempt = create(:answer_attempt, session_question:, answer_text: "Original")
    evaluator = ->(**) { raise "temporary failure" }

    expect { described_class.call(answer_attempt: attempt, evaluator:) }.to raise_error(Interview::EvaluateAnswer::Error)
    expect(attempt.reload.answer_text).to eq("Original")
    expect(attempt.evaluation).to be_nil
  end
end
