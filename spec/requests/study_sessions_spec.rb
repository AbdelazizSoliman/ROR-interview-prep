require "rails_helper"

RSpec.describe "Study sessions", type: :request do
  describe "authentication" do
    it "requires sign-in to create, view, and answer sessions" do
      session = create_session_with_questions(user: create(:user), count: 1)
      session_question = session.session_questions.first

      post study_sessions_path
      expect(response).to redirect_to(new_user_session_path)

      get study_session_path(session)
      expect(response).to redirect_to(new_user_session_path)

      post study_session_session_question_answer_path(session, session_question),
        params: { answer_attempt: { answer_text: "Unauthorized" } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "practice flow" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "starts a session and renders its first question without reference content" do
      question = create_eligible_question(
        reference_answer: "SECRET REFERENCE ANSWER",
        explanation: "SECRET EXPLANATION",
        common_mistakes: "SECRET COMMON MISTAKES"
      )

      post study_sessions_path
      session = user.study_sessions.last
      follow_redirect!
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(question.prompt)
      expect(response.body).to include("Question 1 of 1")
      expect(response.body).not_to include("SECRET REFERENCE ANSWER")
      expect(response.body).not_to include("SECRET EXPLANATION")
      expect(response.body).not_to include("SECRET COMMON MISTAKES")
      expect(session).to be_active
    end

    it "rejects a blank answer and preserves it for redisplay" do
      session = create_session_with_questions(user:, count: 1)
      session_question = session.session_questions.first

      post study_session_session_question_answer_path(session, session_question),
        params: { answer_attempt: { answer_text: "   " } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Answer text can&#39;t be blank")
      expect(AnswerAttempt.count).to be_zero
      expect(session_question.reload.answered_at).to be_nil
    end

    it "stores an answer and redirects to the next question" do
      session = create_session_with_questions(user:, count: 2)
      first, second = session.session_questions.to_a

      post study_session_session_question_answer_path(session, first),
        params: { answer_attempt: { answer_text: "My stored answer" } }

      expect(response).to redirect_to(study_session_session_question_path(session, second))
      expect(first.reload.submitted_answer_attempt.answer_text).to eq("My stored answer")
      expect(first.answered_at).to be_present
    end

    it "completes after the final answer and renders a basic summary" do
      session = create_session_with_questions(user:, count: 1)
      session_question = session.session_questions.first

      post study_session_session_question_answer_path(session, session_question),
        params: { answer_attempt: { answer_text: "Final response" } }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Session complete")
      expect(response.body).to include("1 / 1 questions answered")
      expect(response.body).not_to include("score")
      expect(session.reload).to be_completed
      expect(session.completed_at).to be_present
    end

    it "does not overwrite a submitted answer" do
      session = create_session_with_questions(user:, count: 1)
      session_question = session.session_questions.first
      post study_session_session_question_answer_path(session, session_question),
        params: { answer_attempt: { answer_text: "Original response" } }

      post study_session_session_question_answer_path(session, session_question),
        params: { answer_attempt: { answer_text: "Replacement response" } }

      expect(response).to redirect_to(study_session_path(session))
      expect(session_question.reload.submitted_answer_attempt.answer_text).to eq("Original response")
      expect(AnswerAttempt.where(session_question:).count).to eq(1)
    end

    it "resumes an existing active session instead of creating another" do
      create_eligible_question
      existing = Interview::StudySessions::Create.call(user:).study_session

      post study_sessions_path

      expect(response).to redirect_to(study_session_path(existing))
      expect(user.study_sessions.count).to eq(1)
    end

    it "shows a friendly message when no eligible questions exist" do
      post study_sessions_path
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No Core Mid-Level questions are available yet.")
      expect(user.study_sessions.count).to be_zero
    end

    it "keeps an already-selected question accessible after it becomes inactive" do
      session = create_session_with_questions(user:, count: 1)
      session_question = session.session_questions.first
      session_question.question.update!(active: false)

      get study_session_session_question_path(session, session_question)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(session_question.question.prompt)
    end
  end

  describe "ownership" do
    it "prevents another user from viewing or answering an owned session" do
      owner = create(:user)
      intruder = create(:user)
      session = create_session_with_questions(user: owner, count: 1)
      session_question = session.session_questions.first
      sign_in intruder

      get study_session_path(session)
      expect(response).to have_http_status(:not_found)

      sign_in intruder
      get study_session_session_question_path(session, session_question)
      expect(response).to have_http_status(:not_found)

      sign_in intruder
      post study_session_session_question_answer_path(session, session_question),
        params: { answer_attempt: { answer_text: "Intrusion" } }
      expect(response).to have_http_status(:not_found)
      expect(AnswerAttempt.count).to be_zero
    end
  end

  def create_eligible_question(**attributes)
    create(:question, { difficulty: "mid", priority: "core", active: true }.merge(attributes))
  end

  def create_session_with_questions(user:, count:)
    session = create(:study_session, user:, question_count: count)
    count.times do |position|
      create(:session_question, study_session: session, question: create_eligible_question, position:)
    end
    session.reload
  end
end
