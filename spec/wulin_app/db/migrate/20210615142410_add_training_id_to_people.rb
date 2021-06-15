class AddTrainingIdToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :training_id, :integer
    add_index :people, :training_id
  end
end
