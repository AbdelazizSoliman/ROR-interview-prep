require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with the minimal authentication attributes" do
    expect(build(:user)).to be_valid
  end

  it "requires a unique email address" do
    create(:user, email: "developer@example.com")

    duplicate = build(:user, email: "DEVELOPER@example.com")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:email]).to include("has already been taken")
  end
end
