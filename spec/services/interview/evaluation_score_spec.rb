require "rails_helper"

RSpec.describe Interview::EvaluationScore do
  it "maps weighted coverage to the documented thresholds" do
    expect(described_class.from_coverage(matched_weight: 0, total_weight: 10)).to eq(0)
    expect(described_class.from_coverage(matched_weight: 0.1, total_weight: 10)).to eq(1)
    expect(described_class.from_coverage(matched_weight: 2.5, total_weight: 10)).to eq(2)
    expect(described_class.from_coverage(matched_weight: 5, total_weight: 10)).to eq(3)
    expect(described_class.from_coverage(matched_weight: 7, total_weight: 10)).to eq(4)
    expect(described_class.from_coverage(matched_weight: 9, total_weight: 10)).to eq(5)
  end

  it "returns zero when there is no concept weight" do
    expect(described_class.from_coverage(matched_weight: 1, total_weight: 0)).to eq(0)
  end
end
