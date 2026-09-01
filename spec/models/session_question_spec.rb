require "rails_helper"

RSpec.describe SessionQuestion, type: :model do
  it "requires a session, question, and nonnegative position" do
    record = build(:session_question, study_session: nil, question: nil, position: -1)

    expect(record).not_to be_valid
    expect(record.errors.attribute_names).to include(:study_session, :question, :position)
  end

  it "requires unique questions and positions within a session" do
    session = create(:study_session, question_count: 2)
    existing = create(:session_question, study_session: session, position: 0)

    duplicate_question = build(:session_question, study_session: session, question: existing.question, position: 1)
    duplicate_position = build(:session_question, study_session: session, position: 0)

    expect(duplicate_question).not_to be_valid
    expect(duplicate_position).not_to be_valid
  end
end
