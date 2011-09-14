class CreateGridStatus < ActiveRecord::Migration
  def change
    create_table :grid_status do |t|
      t.integer :user_id
      t.string  :grid_name
      t.string  :status
      t.timestamps
    end
  end
end