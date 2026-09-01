require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "redirects an unauthenticated user to sign in" do
    get dashboard_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the dashboard for an authenticated user" do
    user = create(:user)
    sign_in user

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Welcome back, #{user.email}")
    expect(response.body).to include("Start Core Mid-Level Practice")
    expect(response.body).not_to include("Mastered")
    expect(response.body).not_to include("Due today")
  end
end
