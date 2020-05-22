class AddStatusToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :status, :integer, default: 0
  end
end
