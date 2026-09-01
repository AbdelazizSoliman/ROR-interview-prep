class AddStableKeyToQuestionConcepts < ActiveRecord::Migration[8.1]
  def change
    add_column :question_concepts, :stable_key, :string
    reversible do |direction|
      direction.up do
        execute <<~SQL
          UPDATE question_concepts
          SET stable_key = 'legacy_' || id
          WHERE stable_key IS NULL
        SQL
      end
    end
    change_column_null :question_concepts, :stable_key, false
    add_index :question_concepts, [ :question_id, :stable_key ], unique: true
  end
end
