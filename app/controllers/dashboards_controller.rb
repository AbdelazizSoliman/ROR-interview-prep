class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @active_session = current_user.study_sessions.active.find_by(session_type: "core_mid")
  end
end
