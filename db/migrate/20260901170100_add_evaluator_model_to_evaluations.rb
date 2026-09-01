class AddEvaluatorModelToEvaluations < ActiveRecord::Migration[8.1]
  def change
    add_column :evaluations, :evaluator_model, :string
  end
end
