class SessionQuestionsController < ApplicationController
  before_action :authenticate_user!

  def show
    @study_session = current_user.study_sessions.find(params[:study_session_id])
    @session_question = @study_session.session_questions.includes(:answer_attempts, question: :topic).find(params[:id])

    current_question = @study_session.current_session_question
    if @session_question.answered_at.nil? && current_question != @session_question
      return redirect_to study_session_session_question_path(@study_session, current_question), alert: "Questions must be answered in order."
    end

    @question = @session_question.question
    @submitted_answer_attempt = @session_question.submitted_answer_attempt
    @answer_attempt = AnswerAttempt.new
  end
end
