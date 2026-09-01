require "rails_helper"

RSpec.describe Evaluation, type: :model do
  it "belongs to an answer attempt and validates its score" do
    evaluation = build(:evaluation)
    expect(evaluation).to be_valid
    expect(evaluation.answer_attempt).to be_present
    expect(build(:evaluation, score: 6)).not_to be_valid
  end

  it "allows only one evaluation per answer attempt" do
    evaluation = create(:evaluation)
    duplicate = build(:evaluation, answer_attempt: evaluation.answer_attempt)
    expect(duplicate).not_to be_valid
  end

  it "requires array feedback snapshots and keeps them immutable" do
    evaluation = create(:evaluation, matched_concepts: [ { "concept" => "objects" } ])
    expect { evaluation.update!(score: 5) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(build(:evaluation, matched_concepts: "not an array")).not_to be_valid
  end
end
