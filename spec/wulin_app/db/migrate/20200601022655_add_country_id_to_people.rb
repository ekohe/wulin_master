# frozen_string_literal: true

class AddCountryIdToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :country_id, :integer
    add_index :people, :country_id
  end
end
