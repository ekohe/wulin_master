# frozen_string_literal: true

class PostGrid < WulinMaster::Grid
  title 'Posts'

  model Post

  # path '/posts' # Define a different route for the grid

  column :name

  action :fullscreen, icon: :fullscreen, global: true

  load_default_actions # Add default toolbar items for this grid
end
