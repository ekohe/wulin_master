require 'rails/generators'
require 'rails/generators/active_record'

module WulinMaster
  class GridViewGenerator < ActiveRecord::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    argument :name
    class_option :model, :type => :boolean, :default => true, :desc=> "Create model"
    class_option :controller,  :type => :boolean, :default => true, :desc => 'Create controller for current grid'
    class_option :routes,  :type => :boolean, :default => true, :desc => 'Config routes for current grid'

    def create_model
      template "model.rb", "app/models/#{underscored_name}.rb" if options.model?
    end

    def create_controller
      template "controller.rb", "app/controllers/#{table_name}_controller.rb" if options.controller?
    end

    def create_screen
      template "screen.rb", "app/screens/#{underscored_name}_screen.rb"
    end

    def create_grid
      template "grid.rb", "app/grids/#{underscored_name}_grid.rb"
    end

    def add_route
      route "resources :#{table_name}" if options.routes?
    end
    

    private

    def underscored_name
      name.underscore.singularize
    end

    def class_name
      name.classify
    end

    def human_name
      name.underscore.humanize.pluralize
    end

  end
end