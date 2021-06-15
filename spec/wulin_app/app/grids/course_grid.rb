# frozen_string_literal: true

class CourseGrid < WulinMaster::Grid
  title 'Courses'

  model Course

  # path '/courses' # Define a different route for the grid

  column :name
  column :training_id

  load_default_actions # Add default toolbar items for this grid
end
