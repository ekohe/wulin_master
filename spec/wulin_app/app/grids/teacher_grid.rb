# frozen_string_literal: true

class TeacherGrid < WulinMaster::Grid
  title "Teachers"

  model Teacher

  # path '/teachers' # Define a different route for the grid

  column :name
  column :students, sql_expression: "people.first_name"
  # need to be developed
  # column :training_students
  column :courses
  column :clients

  action :fullscreen, icon: :fullscreen, global: true

  load_default_actions # Add default toolbar items for this grid
end
