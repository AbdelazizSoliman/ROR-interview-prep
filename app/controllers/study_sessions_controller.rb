class StudySessionsController < ApplicationController
  before_action :authenticate_user!

  def create
    result = Interview::StudySessions::Create.call(user: current_user)
    message = result.resumed ? "Resuming your active practice session." : "Practice session started."
    redirect_to study_session_path(result.study_session), notice: message
  rescue Interview::StudySessions::Create::NoQuestionsAvailable => error
    redirect_to dashboard_path, alert: error.message
  end

  def show
    @study_session = current_user.study_sessions.includes(session_questions: { question: :topic }).find(params[:id])

    if @study_session.active?
      redirect_to study_session_session_question_path(@study_session, @study_session.current_session_question)
    elsif !@study_session.completed?
      redirect_to dashboard_path, alert: "This practice session is not active."
    end
  end
end
