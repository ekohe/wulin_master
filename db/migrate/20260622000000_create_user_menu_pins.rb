class CreateUserMenuPins < ActiveRecord::Migration[5.0]
  def change
    create_table :user_preferences do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
      t.text :value
      t.timestamps
    end
    add_index :user_preferences, [:user_id, :name], unique: true
    add_index :user_preferences, :user_id
  end
end
