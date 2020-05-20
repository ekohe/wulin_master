# frozen_string_literal: true

class PersonGrid < WulinMaster::Grid
  JOBS = %w[Developer DevOps Designer PM].freeze
  title 'People'

  model Person

  # path '/people' # Define a different route for the grid

  column :first_name
  column :last_name
  column :age
  column :signature
  column :birthdate
  column :job, choices: JOBS, editor: 'SelectEditor'
  column :vip

  load_default_actions # Add default toolbar items for this grid
end
