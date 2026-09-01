require "rails_helper"

RSpec.describe QuestionConcept, type: :model do
  it "requires a question, concept, positive weight, and nonnegative position" do
    concept = build(:question_concept, question: nil, concept: nil, weight: 0, position: -1)

    expect(concept).not_to be_valid
    expect(concept.errors.attribute_names).to include(:question, :concept, :weight, :position)
  end

  it "orders concepts deterministically by position and id" do
    question = create(:question)
    second = create(:question_concept, question:, concept: "Second", position: 1)
    first = create(:question_concept, question:, concept: "First", position: 0)

    expect(question.question_concepts).to eq([ first, second ])
  end
end
