# frozen_string_literal: true

class PersonGrid < WulinMaster::Grid
  title 'People'

  model Person

  # path '/people' # Define a different route for the grid

  column :first_name
  column :last_name
  column :birthdate

  load_default_actions # Add default toolbar items for this grid
end
