class EvaluationsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_context

  def show
  end

  def create
    unless @answer_attempt
      return redirect_to study_session_session_question_path(@study_session, @session_question), alert: "Answer the question before requesting an evaluation."
    end

    Interview::EvaluateAnswer.call(answer_attempt: @answer_attempt)
    redirect_to study_session_session_question_evaluation_path(@study_session, @session_question)
  rescue Interview::EvaluateAnswer::Error => error
    redirect_to study_session_session_question_evaluation_path(@study_session, @session_question), alert: error.message
  end

  private

  def load_context
    @study_session = current_user.study_sessions.find(params[:study_session_id])
    @session_question = @study_session.session_questions.includes(:answer_attempts, question: :topic).find(params[:session_question_id])
    current_question = @study_session.current_session_question

    if @session_question.answered_at.nil?
      return redirect_to study_session_session_question_path(@study_session, current_question) if current_question != @session_question
    end

    @question = @session_question.question
    @answer_attempt = @session_question.submitted_answer_attempt
    @evaluation = @answer_attempt&.evaluation
  end
end
