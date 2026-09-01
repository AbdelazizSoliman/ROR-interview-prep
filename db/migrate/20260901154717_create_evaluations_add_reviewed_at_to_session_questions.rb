class CreateEvaluationsAddReviewedAtToSessionQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :session_questions, :reviewed_at, :datetime

    create_table :evaluations do |t|
      t.references :answer_attempt, null: false, foreign_key: true, index: { unique: true }
      t.integer :score, null: false
      t.text :summary
      t.text :stronger_answer, null: false
      t.jsonb :matched_concepts, null: false, default: []
      t.jsonb :missing_concepts, null: false, default: []
      t.jsonb :misconceptions, null: false, default: []
      t.string :evaluator_type, null: false
      t.datetime :evaluated_at, null: false
      t.timestamps
    end
    add_check_constraint :evaluations, "score BETWEEN 0 AND 5", name: "evaluations_score_allowed"
    add_check_constraint :evaluations, "jsonb_typeof(matched_concepts) = 'array'", name: "evaluations_matched_concepts_array"
    add_check_constraint :evaluations, "jsonb_typeof(missing_concepts) = 'array'", name: "evaluations_missing_concepts_array"
    add_check_constraint :evaluations, "jsonb_typeof(misconceptions) = 'array'", name: "evaluations_misconceptions_array"
  end
end
