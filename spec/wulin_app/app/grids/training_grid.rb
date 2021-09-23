# frozen_string_literal: true

class TrainingGrid < WulinMaster::Grid
  title "Trainings"

  model Training

  # path '/trainings' # Define a different route for the grid

  column :name
  column :teacher_id

  load_default_actions # Add default toolbar items for this grid
end
