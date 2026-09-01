class SessionProgressionsController < ApplicationController
  before_action :authenticate_user!

  def create
    study_session = current_user.study_sessions.find(params[:study_session_id])
    session_question = study_session.session_questions.find(params[:session_question_id])
    result = Interview::StudySessions::Continue.call(study_session:, session_question:)

    if result.completed
      redirect_to study_session_path(study_session), notice: "Session complete."
    elsif result.next_session_question.answered_at.present?
      redirect_to study_session_session_question_evaluation_path(study_session, result.next_session_question)
    else
      redirect_to study_session_session_question_path(study_session, result.next_session_question)
    end
  rescue Interview::StudySessions::Continue::InvalidProgression => error
    redirect_to study_session_session_question_evaluation_path(study_session, session_question), alert: error.message
  end
end
