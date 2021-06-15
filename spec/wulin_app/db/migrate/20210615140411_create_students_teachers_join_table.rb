class CreateStudentsTeachersJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_join_table :students, :teachers
  end
end
