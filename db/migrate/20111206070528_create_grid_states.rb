class CreateGridStates < ActiveRecord::Migration
  def change
    unless table_exists?(:grid_states)
      create_table :grid_states do |t|
        t.integer :user_id
        t.string  :grid_name
        t.text    :state_value
        t.text    :name,  :default => "default" 
        t.boolean :current, :default => false, :null => false 
        t.timestamps
      end
      add_index :grid_states, :user_id
    end
  end
end
