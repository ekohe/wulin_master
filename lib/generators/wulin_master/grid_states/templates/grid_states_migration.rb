class CreateGridStates < ActiveRecord::Migration
  def change
    create_table :grid_states do |t|
      t.integer :user_id
      t.string  :grid_name
      t.string  :state_type
      t.string  :state_value
      t.timestamps
    end
    add_index :grid_states, :user_id
  end
end
