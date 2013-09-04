class ChangeGridStatesTableToEnableMultipleStates < ActiveRecord::Migration
  def up
    remove_column :grid_states, :state_type if column_exists?(:grid_states, :state_type)
    add_column :grid_states, :name, :string, :default => "default" unless column_exists?(:grid_states, :name)
    add_column :grid_states, :current, :boolean, :default => false, :null => false unless column_exists?(:grid_states, :current)

    WulinMaster::GridState.update_all({:name => 'default', :current => true})
  end

  def down
    remove_column :grid_states, :current if column_exists?(:grid_states, :current)
    remove_column :grid_states, :name if column_exists?(:grid_states, :name)
    add_column :grid_states, :state_type, :string unless column_exists?(:grid_states, :state_type)
  end
end
