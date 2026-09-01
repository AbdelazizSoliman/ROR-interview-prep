class CreateStudySessionsAndAnswerAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :study_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :session_type, null: false
      t.string :status, null: false
      t.integer :question_count, null: false
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :study_sessions, [ :user_id, :session_type ], unique: true, where: "status = 'active'", name: "index_study_sessions_on_unique_active_type"
    add_check_constraint :study_sessions, "session_type IN ('core_mid')", name: "study_sessions_type_allowed"
    add_check_constraint :study_sessions, "status IN ('active', 'completed', 'abandoned')", name: "study_sessions_status_allowed"
    add_check_constraint :study_sessions, "question_count > 0", name: "study_sessions_question_count_positive"

    create_table :session_questions do |t|
      t.references :study_session, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :position, null: false
      t.datetime :answered_at
      t.timestamps
    end
    add_index :session_questions, [ :study_session_id, :question_id ], unique: true
    add_index :session_questions, [ :study_session_id, :position ], unique: true
    add_check_constraint :session_questions, "position >= 0", name: "session_questions_position_nonnegative"

    create_table :answer_attempts do |t|
      t.references :session_question, null: false, foreign_key: true
      t.text :answer_text, null: false
      t.datetime :submitted_at, null: false
      t.timestamps
    end
    add_check_constraint :answer_attempts, "btrim(answer_text) <> ''", name: "answer_attempts_text_not_blank"
  end
end
