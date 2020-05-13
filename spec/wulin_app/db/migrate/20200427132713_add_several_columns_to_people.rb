# frozen_string_literal: true

class AddSeveralColumnsToPeople < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :job, :string
    add_column :people, :vip, :boolean, default: false
  end
end
