require "rails_helper"

RSpec.describe Topic, type: :model do
  it "requires a name and a unique, valid slug" do
    create(:topic, slug: "active-record")

    topic = build(:topic, name: nil, slug: "active-record")

    expect(topic).not_to be_valid
    expect(topic.errors[:name]).to be_present
    expect(topic.errors[:slug]).to include("has already been taken")
    expect(build(:topic, slug: "Invalid Slug")).not_to be_valid
  end

  it "keeps its slug stable after creation" do
    topic = create(:topic, slug: "ruby")

    expect { topic.update!(slug: "changed") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    expect(topic.reload.slug).to eq("ruby")
  end

  it "returns questions in position order" do
    topic = create(:topic)
    second = create(:question, topic:, position: 2)
    first = create(:question, topic:, position: 1)

    expect(topic.questions).to eq([ first, second ])
  end
end
