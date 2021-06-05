# frozen_string_literal: true

class PostGrid < WulinMaster::Grid
  title 'Posts'

  model Post

  # path '/posts' # Define a different route for the grid

  column :name
  column :first_name, through: :person, label: :person_first_name
  column :person, source: :last_name, label: :person_last_name
  column :person_job

  action :fullscreen, icon: :fullscreen, global: true

  load_default_actions # Add default toolbar items for this grid
end
