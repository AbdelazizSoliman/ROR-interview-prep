require "rails_helper"

RSpec.describe QuestionFollowUp, type: :model do
  it "requires both question references" do
    follow_up = build(:question_follow_up, question: nil, follow_up_question: nil)

    expect(follow_up).not_to be_valid
    expect(follow_up.errors.attribute_names).to include(:question, :follow_up_question)
  end

  it "prevents a question from following up itself" do
    question = create(:question)

    follow_up = build(:question_follow_up, question:, follow_up_question: question)

    expect(follow_up).not_to be_valid
    expect(follow_up.errors[:follow_up_question]).to include("must be different from the source question")
  end

  it "prevents duplicate question pairs" do
    source = create(:question)
    target = create(:question)
    create(:question_follow_up, question: source, follow_up_question: target)

    duplicate = build(:question_follow_up, question: source, follow_up_question: target, relationship_type: "deeper")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:follow_up_question_id]).to include("has already been taken")
  end

  it "validates relationship type" do
    expect(build(:question_follow_up, relationship_type: "related")).to be_valid
    expect(build(:question_follow_up, relationship_type: "prerequisite")).not_to be_valid
  end
end
