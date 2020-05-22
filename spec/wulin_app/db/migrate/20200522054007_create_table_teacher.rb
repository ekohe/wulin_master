# frozen_string_literal: true

class CreateTableTeacher < ActiveRecord::Migration[6.0]
  def change
    create_table :teachers do |t|
      t.string :name
      t.string :subject
    end
  end
end
