require "rails_helper"

RSpec.describe "Home", type: :request do
  it "renders the public landing page" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Ruby &amp; Rails Interview Prep")
    expect(response.body).to include("Practice technical interview questions")
  end

  it "redirects an authenticated user to the dashboard" do
    sign_in create(:user)

    get root_path

    expect(response).to redirect_to(dashboard_path)
  end
end
