class CreateAddresses < ActiveRecord::Migration[5.0]
  def change
    create_table :addresses do |t|
      t.string :country
      t.string :city
      t.integer :country_id
      t.integer :city_id

      t.timestamps
    end
  end
end
