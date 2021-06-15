# frozen_string_literal: true

class ClientGrid < WulinMaster::Grid
  title 'Clients'

  model Client

  # path '/clients' # Define a different route for the grid

  column :name

  load_default_actions # Add default toolbar items for this grid
end
