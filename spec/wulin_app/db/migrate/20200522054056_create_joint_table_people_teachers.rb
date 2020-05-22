# frozen_string_literal: true

class CreateJointTablePeopleTeachers < ActiveRecord::Migration[6.0]
  def change
    create_join_table :people, :teachers do |t|
      t.index :person_id
      t.index :teacher_id
    end
  end
end
