class CreateQuestionBank < ActiveRecord::Migration[8.1]
  def change
    create_table :topics do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :topics, :slug, unique: true
    add_check_constraint :topics, "position >= 0", name: "topics_position_nonnegative"

    create_table :questions do |t|
      t.references :topic, null: false, foreign_key: true
      t.string :stable_key, null: false
      t.string :short_title
      t.text :prompt, null: false
      t.string :difficulty, null: false
      t.string :priority, null: false
      t.string :question_type, null: false
      t.text :reference_answer, null: false
      t.text :explanation
      t.text :common_mistakes
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :questions, :stable_key, unique: true
    add_index :questions, :difficulty
    add_index :questions, :priority
    add_index :questions, :question_type
    add_index :questions, :active
    add_check_constraint :questions, "difficulty IN ('junior', 'mid', 'strong_mid', 'senior')", name: "questions_difficulty_allowed"
    add_check_constraint :questions, "priority IN ('core', 'important', 'advanced')", name: "questions_priority_allowed"
    add_check_constraint :questions, "question_type IN ('knowledge', 'comparison', 'debugging', 'production_scenario', 'architecture', 'code_reasoning', 'sql')", name: "questions_type_allowed"
    add_check_constraint :questions, "position >= 0", name: "questions_position_nonnegative"

    create_table :question_concepts do |t|
      t.references :question, null: false, foreign_key: true
      t.text :concept, null: false
      t.text :explanation
      t.decimal :weight, precision: 6, scale: 2, null: false, default: 1
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :question_concepts, "weight > 0", name: "question_concepts_weight_positive"
    add_check_constraint :question_concepts, "position >= 0", name: "question_concepts_position_nonnegative"

    create_table :question_follow_ups do |t|
      t.references :question, null: false, foreign_key: true
      t.references :follow_up_question, null: false, foreign_key: { to_table: :questions }
      t.string :relationship_type, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :question_follow_ups, [ :question_id, :follow_up_question_id ], unique: true, name: "index_question_follow_ups_on_question_pair"
    add_check_constraint :question_follow_ups, "question_id <> follow_up_question_id", name: "question_follow_ups_not_self"
    add_check_constraint :question_follow_ups, "relationship_type IN ('follow_up', 'deeper', 'related')", name: "question_follow_ups_type_allowed"
    add_check_constraint :question_follow_ups, "position >= 0", name: "question_follow_ups_position_nonnegative"
  end
end
