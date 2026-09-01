require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "registration" do
    it "creates and signs in a user" do
      expect do
        post user_registration_path, params: {
          user: {
            email: "new-user@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end.to change(User, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "sign in" do
    it "authenticates a user with valid credentials" do
      user = create(:user)

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(dashboard_path)
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "sign out" do
    it "ends the authenticated session" do
      user = create(:user)
      sign_in user

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "password reset" do
    it "generates a reset token and sends instructions" do
      user = create(:user)

      expect do
        post user_password_path, params: { user: { email: user.email } }
      end.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to redirect_to(new_user_session_path)
      expect(user.reload.reset_password_token).to be_present
      expect(user.reset_password_sent_at).to be_present
    end
  end
end
