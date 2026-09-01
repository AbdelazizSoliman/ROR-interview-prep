require "rails_helper"

RSpec.describe Question, type: :model do
  it "requires its topic, stable key, prompt, and reference answer" do
    question = build(:question, topic: nil, stable_key: nil, prompt: nil, reference_answer: nil)

    expect(question).not_to be_valid
    expect(question.errors.attribute_names).to include(:topic, :stable_key, :prompt, :reference_answer)
  end

  it "requires a globally unique stable key" do
    create(:question, stable_key: "ruby.objects.mutation")

    duplicate = build(:question, stable_key: "ruby.objects.mutation")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:stable_key]).to include("has already been taken")
  end

  it "keeps its stable key immutable after creation" do
    question = create(:question, stable_key: "ruby.objects.mutation")

    expect { question.update!(stable_key: "ruby.objects.changed") }
      .to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(question.reload.stable_key).to eq("ruby.objects.mutation")
  end

  it "validates difficulty values" do
    expect(build(:question, difficulty: "junior")).to be_valid
    expect(build(:question, difficulty: "principal")).not_to be_valid
  end

  it "validates priority values" do
    expect(build(:question, priority: "core")).to be_valid
    expect(build(:question, priority: "optional")).not_to be_valid
  end

  it "validates question type values" do
    expect(build(:question, question_type: "production_scenario")).to be_valid
    expect(build(:question, question_type: "trivia")).not_to be_valid
  end
end
