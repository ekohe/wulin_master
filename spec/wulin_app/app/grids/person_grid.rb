# frozen_string_literal: true

class PersonGrid < WulinMaster::Grid
  JOBS = %w[Developer DevOps Designer PM].freeze
  title 'People'

  model Person

  # path '/people' # Define a different route for the grid

  # string
  column :first_name
  column :last_name
  # integer
  column :age
  # text
  column :signature
  # datetime
  column :birthdate
  # string -> selector
  column :job, choices: JOBS, editor: 'SelectEditor'
  # belongs_to
  column :country
  # enum
  column :status, choices: Person.statuses.keys
  # has_many -> multiple selector
  column :teachers
  # boolean
  column :vip

  action :fullscreen, icon: :fullscreen, global: true

  load_default_actions # Add default toolbar items for this grid
end
