# frozen_string_literal: true

class TeacherGrid < WulinMaster::Grid
  title 'Teachers'

  model Teacher

  # path '/teachers' # Define a different route for the grid

  column :name

  action :fullscreen, icon: :fullscreen, global: true

  load_default_actions # Add default toolbar items for this grid
end
