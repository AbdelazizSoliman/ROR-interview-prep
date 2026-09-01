require "rails_helper"

RSpec.describe "Evaluations", type: :request do
  it "shows persisted feedback and does not duplicate on refresh" do
    user = create(:user)
    sign_in user
    session = create(:study_session, user:, question_count: 1)
    question = create(:question, reference_answer: "Reference answer")
    session_question = create(:session_question, study_session: session, question:, answered_at: Time.current)
    create(:question_concept, question:, concept: "Ruby")
    attempt = create(:answer_attempt, session_question:, answer_text: "Ruby")
    Interview::EvaluateAnswer.call(answer_attempt: attempt)

    get study_session_session_question_evaluation_path(session, session_question)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Your answer", "Reference answer", "Recall score")
    expect(Evaluation.where(answer_attempt: attempt).count).to eq(1)

    get study_session_session_question_evaluation_path(session, session_question)
    expect(Evaluation.where(answer_attempt: attempt).count).to eq(1)
  end

  it "prevents another user from viewing or continuing an evaluation" do
    owner = create(:user)
    intruder = create(:user)
    session = create(:study_session, user: owner, question_count: 1)
    session_question = create(:session_question, study_session: session, answered_at: Time.current)
    attempt = create(:answer_attempt, session_question:)
    create(:evaluation, answer_attempt: attempt)
    sign_in intruder

    get study_session_session_question_evaluation_path(session, session_question)
    expect(response).to have_http_status(:not_found)

    sign_in intruder
    post study_session_session_question_continue_path(session, session_question)
    expect(response).to have_http_status(:not_found)
  end

  it "requires authentication" do
    session = create(:study_session, question_count: 1)
    session_question = create(:session_question, study_session: session, answered_at: Time.current)

    get study_session_session_question_evaluation_path(session, session_question)
    expect(response).to redirect_to(new_user_session_path)
  end

  it "keeps the answer when evaluation fails and allows a retry" do
    user = create(:user)
    sign_in user
    session = create(:study_session, user:, question_count: 1)
    session_question = create(:session_question, study_session: session)
    allow(Interview::EvaluateAnswer).to receive(:call).and_raise(Interview::EvaluateAnswer::Error, "temporary evaluator failure")

    post study_session_session_question_answer_path(session, session_question),
      params: { answer_attempt: { answer_text: "Persisted answer" } }

    expect(response).to redirect_to(study_session_session_question_evaluation_path(session, session_question))
    expect(session_question.reload.submitted_answer_attempt.answer_text).to eq("Persisted answer")
    expect(session_question.reload.submitted_answer_attempt.evaluation).to be_nil

    allow(Interview::EvaluateAnswer).to receive(:call).and_call_original
    post study_session_session_question_evaluation_path(session, session_question)

    expect(response).to redirect_to(study_session_session_question_evaluation_path(session, session_question))
    expect(session_question.reload.submitted_answer_attempt.evaluation).to be_present
  end
end
