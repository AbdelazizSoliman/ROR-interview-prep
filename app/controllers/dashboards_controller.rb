class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @active_session = current_user.study_sessions.active.find_by(session_type: "core_mid")
    @active_daily_review = current_user.study_sessions.active.find_by(session_type: "daily_review")
    @due_review_count = current_user.review_schedules.where("next_review_at <= ?", Time.current).joins(:question).where(questions: { active: true }).count
  end
end
