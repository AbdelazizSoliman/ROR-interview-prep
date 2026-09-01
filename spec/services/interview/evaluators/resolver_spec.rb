require "rails_helper"

RSpec.describe Interview::Evaluators::Resolver do
  around do |example|
    previous = ENV["INTERVIEW_EVALUATOR"]
    previous_key = ENV["OPENAI_API_KEY"]
    example.run
  ensure
    ENV["INTERVIEW_EVALUATOR"] = previous
    ENV["OPENAI_API_KEY"] = previous_key
  end

  it "uses deterministic evaluation by default" do
    ENV.delete("INTERVIEW_EVALUATOR")
    expect(described_class.call).to be_a(Interview::Evaluators::Deterministic)
  end

  it "selects AI only when explicitly configured" do
    ENV["INTERVIEW_EVALUATOR"] = "ai"
    ENV["OPENAI_API_KEY"] = "test-key"
    expect(described_class.call).to be_a(Interview::Evaluators::AI)
  end

  it "rejects unknown evaluator modes" do
    ENV["INTERVIEW_EVALUATOR"] = "unknown"
    expect { described_class.call }.to raise_error(ArgumentError)
  end
end
