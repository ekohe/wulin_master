# frozen_string_literal: true

class PostGrid < WulinMaster::Grid
  title "Posts"

  model Post

  # path '/posts' # Define a different route for the grid

  column :name
  column :first_name, through: :person, label: :person_first_name
  column :person, source: :last_name, label: :person_last_name
  column :person_job, sql_expression: "people.job"
  # forbide
  # column :country_name, through: :person
  # not recommand
  # column :country_name, sql_expression: 'countries.name'
  # recommand
  column :country_name, source: :name, through: :country

  action :fullscreen, icon: :fullscreen, global: true

  load_default_actions # Add default toolbar items for this grid
end
