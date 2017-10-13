# frozen_string_literal: true

class CreatePeople < ActiveRecord::Migration[5.0]
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.datetime :birthdate

      t.timestamps
    end
  end
end
