class AnswerAttemptsController < ApplicationController
  before_action :authenticate_user!

  def create
    @study_session = current_user.study_sessions.find(params[:study_session_id])
    @session_question = @study_session.session_questions.includes(question: :topic).find(params[:session_question_id])
    result = Interview::StudySessions::SubmitAnswer.call(
      study_session: @study_session,
      session_question: @session_question,
      answer_text: answer_attempt_params[:answer_text]
    )

    if result.success?
      redirect_after_success(result)
    else
      @question = @session_question.question
      @answer_attempt = result.answer_attempt
      render "session_questions/show", status: :unprocessable_content
    end
  rescue Interview::StudySessions::SubmitAnswer::InvalidSubmission => error
    redirect_to study_session_path(@study_session), alert: error.message
  end

  private

  def answer_attempt_params
    params.expect(answer_attempt: [ :answer_text ])
  end

  def redirect_after_success(result)
    if result.completed
      redirect_to study_session_path(@study_session), notice: "Session complete."
    else
      redirect_to study_session_session_question_path(@study_session, result.next_session_question)
    end
  end
end
