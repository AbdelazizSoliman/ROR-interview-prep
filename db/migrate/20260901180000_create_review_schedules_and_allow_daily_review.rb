class CreateReviewSchedulesAndAllowDailyReview < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :study_sessions, name: "study_sessions_type_allowed"
    add_check_constraint :study_sessions, "session_type::text = ANY (ARRAY['core_mid'::character varying, 'daily_review'::character varying]::text[])", name: "study_sessions_type_allowed"

    create_table :review_schedules do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :state, null: false
      t.integer :attempts_count, null: false, default: 0
      t.integer :successful_reviews, null: false, default: 0
      t.integer :last_score
      t.integer :best_score
      t.decimal :average_score, precision: 4, scale: 2
      t.integer :consecutive_successes, null: false, default: 0
      t.integer :interval_days, null: false, default: 0
      t.datetime :last_reviewed_at
      t.datetime :next_review_at
      t.timestamps
    end

    add_index :review_schedules, [ :user_id, :question_id ], unique: true
    add_index :review_schedules, [ :user_id, :next_review_at ]
    add_check_constraint :review_schedules, "attempts_count >= 0 AND successful_reviews >= 0 AND consecutive_successes >= 0 AND interval_days >= 0", name: "review_schedules_counters_nonnegative"
    add_check_constraint :review_schedules, "(last_score IS NULL OR last_score BETWEEN 0 AND 5) AND (best_score IS NULL OR best_score BETWEEN 0 AND 5) AND (average_score IS NULL OR average_score BETWEEN 0 AND 5)", name: "review_schedules_scores_allowed"
  end
end
