class CreatePeople < ActiveRecord::Migration
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :birthdate

      t.timestamps
    end
  end
end
