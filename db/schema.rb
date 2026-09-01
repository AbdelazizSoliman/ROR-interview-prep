# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_01_142658) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "answer_attempts", force: :cascade do |t|
    t.text "answer_text", null: false
    t.datetime "created_at", null: false
    t.bigint "session_question_id", null: false
    t.datetime "submitted_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_question_id"], name: "index_answer_attempts_on_session_question_id"
    t.check_constraint "btrim(answer_text) <> ''::text", name: "answer_attempts_text_not_blank"
  end

  create_table "question_concepts", force: :cascade do |t|
    t.text "concept", null: false
    t.datetime "created_at", null: false
    t.text "explanation"
    t.integer "position", default: 0, null: false
    t.bigint "question_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 6, scale: 2, default: "1.0", null: false
    t.index ["question_id"], name: "index_question_concepts_on_question_id"
    t.check_constraint "\"position\" >= 0", name: "question_concepts_position_nonnegative"
    t.check_constraint "weight > 0::numeric", name: "question_concepts_weight_positive"
  end

  create_table "question_follow_ups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "follow_up_question_id", null: false
    t.integer "position", default: 0, null: false
    t.bigint "question_id", null: false
    t.string "relationship_type", null: false
    t.datetime "updated_at", null: false
    t.index ["follow_up_question_id"], name: "index_question_follow_ups_on_follow_up_question_id"
    t.index ["question_id", "follow_up_question_id"], name: "index_question_follow_ups_on_question_pair", unique: true
    t.index ["question_id"], name: "index_question_follow_ups_on_question_id"
    t.check_constraint "\"position\" >= 0", name: "question_follow_ups_position_nonnegative"
    t.check_constraint "question_id <> follow_up_question_id", name: "question_follow_ups_not_self"
    t.check_constraint "relationship_type::text = ANY (ARRAY['follow_up'::character varying, 'deeper'::character varying, 'related'::character varying]::text[])", name: "question_follow_ups_type_allowed"
  end

  create_table "questions", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "common_mistakes"
    t.datetime "created_at", null: false
    t.string "difficulty", null: false
    t.text "explanation"
    t.integer "position", default: 0, null: false
    t.string "priority", null: false
    t.text "prompt", null: false
    t.string "question_type", null: false
    t.text "reference_answer", null: false
    t.string "short_title"
    t.string "stable_key", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_questions_on_active"
    t.index ["difficulty"], name: "index_questions_on_difficulty"
    t.index ["priority"], name: "index_questions_on_priority"
    t.index ["question_type"], name: "index_questions_on_question_type"
    t.index ["stable_key"], name: "index_questions_on_stable_key", unique: true
    t.index ["topic_id"], name: "index_questions_on_topic_id"
    t.check_constraint "\"position\" >= 0", name: "questions_position_nonnegative"
    t.check_constraint "difficulty::text = ANY (ARRAY['junior'::character varying, 'mid'::character varying, 'strong_mid'::character varying, 'senior'::character varying]::text[])", name: "questions_difficulty_allowed"
    t.check_constraint "priority::text = ANY (ARRAY['core'::character varying, 'important'::character varying, 'advanced'::character varying]::text[])", name: "questions_priority_allowed"
    t.check_constraint "question_type::text = ANY (ARRAY['knowledge'::character varying, 'comparison'::character varying, 'debugging'::character varying, 'production_scenario'::character varying, 'architecture'::character varying, 'code_reasoning'::character varying, 'sql'::character varying]::text[])", name: "questions_type_allowed"
  end

  create_table "session_questions", force: :cascade do |t|
    t.datetime "answered_at"
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.bigint "question_id", null: false
    t.bigint "study_session_id", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_session_questions_on_question_id"
    t.index ["study_session_id", "position"], name: "index_session_questions_on_study_session_id_and_position", unique: true
    t.index ["study_session_id", "question_id"], name: "index_session_questions_on_study_session_id_and_question_id", unique: true
    t.index ["study_session_id"], name: "index_session_questions_on_study_session_id"
    t.check_constraint "\"position\" >= 0", name: "session_questions_position_nonnegative"
  end

  create_table "study_sessions", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "question_count", null: false
    t.string "session_type", null: false
    t.datetime "started_at", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "session_type"], name: "index_study_sessions_on_unique_active_type", unique: true, where: "((status)::text = 'active'::text)"
    t.index ["user_id"], name: "index_study_sessions_on_user_id"
    t.check_constraint "question_count > 0", name: "study_sessions_question_count_positive"
    t.check_constraint "session_type::text = 'core_mid'::text", name: "study_sessions_type_allowed"
    t.check_constraint "status::text = ANY (ARRAY['active'::character varying, 'completed'::character varying, 'abandoned'::character varying]::text[])", name: "study_sessions_status_allowed"
  end

  create_table "topics", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_topics_on_slug", unique: true
    t.check_constraint "\"position\" >= 0", name: "topics_position_nonnegative"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "answer_attempts", "session_questions"
  add_foreign_key "question_concepts", "questions"
  add_foreign_key "question_follow_ups", "questions"
  add_foreign_key "question_follow_ups", "questions", column: "follow_up_question_id"
  add_foreign_key "questions", "topics"
  add_foreign_key "session_questions", "questions"
  add_foreign_key "session_questions", "study_sessions"
  add_foreign_key "study_sessions", "users"
end
