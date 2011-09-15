class CreateGridStates < ActiveRecord::Migration
  def change
    create_table :grid_states do |t|
      t.integer :user_id
      t.string  :grid_name
      t.string  :states
      t.timestamps
    end
  end
end