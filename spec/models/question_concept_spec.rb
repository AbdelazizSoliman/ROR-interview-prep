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

  it "requires a stable key unique within its question" do
    question = create(:question)
    create(:question_concept, question:, stable_key: "identity")
    duplicate = build(:question_concept, question:, stable_key: "identity")

    expect(duplicate).not_to be_valid
    expect(build(:question_concept, question:, stable_key: "bad-key")).not_to be_valid
  end

  it "does not silently change a stable key after creation" do
    concept = create(:question_concept, stable_key: "published_key")

    expect { concept.update!(stable_key: "new_key") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end
end
