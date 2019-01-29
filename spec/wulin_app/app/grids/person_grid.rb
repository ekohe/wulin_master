# frozen_string_literal: true

class PersonGrid < WulinMaster::Grid
  title 'People'

  model Person

  # path '/people' # Define a different route for the grid

  # frozen_column 1
  # row_detail useRowClick: true, hideRow: true, showTriggerColumn: false

  column :first_name
  column :last_name
  column :birthdate

  # 0.upto(6) { column :last_name }

  load_default_actions # Add default toolbar items for this grid
end
