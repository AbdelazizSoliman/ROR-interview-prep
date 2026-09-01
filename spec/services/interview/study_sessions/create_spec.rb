require "rails_helper"

RSpec.describe Interview::StudySessions::Create do
  let(:user) { create(:user) }

  it "selects only active core mid and strong-mid questions" do
    eligible_mid = create_question(difficulty: "mid", priority: "core")
    eligible_strong_mid = create_question(difficulty: "strong_mid", priority: "core")
    create_question(difficulty: "junior", priority: "core")
    create_question(difficulty: "senior", priority: "core")
    create_question(difficulty: "mid", priority: "important")
    create_question(difficulty: "strong_mid", priority: "advanced")
    create_question(difficulty: "mid", priority: "core", active: false)

    session = described_class.call(user:).study_session

    expect(session.questions).to contain_exactly(eligible_mid, eligible_strong_mid)
  end

  it "selects at most ten questions without duplicates" do
    12.times { |position| create_question(position:) }

    session = described_class.call(user:).study_session

    expect(session.question_count).to eq(10)
    expect(session.question_ids.uniq.length).to eq(10)
  end

  it "uses all eligible questions when fewer than ten exist" do
    3.times { |position| create_question(position:) }

    session = described_class.call(user:).study_session

    expect(session.question_count).to eq(3)
  end

  it "orders by topic position, question position, then stable key" do
    later_topic = create(:topic, position: 2)
    earlier_topic = create(:topic, position: 1)
    last = create_question(topic: later_topic, position: 0, stable_key: "rails.last.question")
    beta = create_question(topic: earlier_topic, position: 1, stable_key: "ruby.beta.question")
    alpha = create_question(topic: earlier_topic, position: 1, stable_key: "ruby.alpha.question")

    session = described_class.call(user:).study_session

    expect(session.questions).to eq([ alpha, beta, last ])
    expect(session.session_questions.pluck(:position)).to eq([ 0, 1, 2 ])
  end

  it "fails cleanly rather than creating a zero-question session" do
    expect { described_class.call(user:) }
      .to raise_error(described_class::NoQuestionsAvailable, "No Core Mid-Level questions are available yet.")
    expect(StudySession.count).to be_zero
  end

  it "resumes an existing active core-mid session" do
    create_question
    existing = described_class.call(user:).study_session

    result = described_class.call(user:)

    expect(result.study_session).to eq(existing)
    expect(result.resumed).to be(true)
    expect(user.study_sessions.count).to eq(1)
  end

  def create_question(topic: nil, **attributes)
    create(:question, { topic: topic || create(:topic) }.merge(attributes))
  end
end
