require 'rails/generators'
require 'rails/generators/active_record'

module WulinMaster
  class ScreenAndGridGenerator < ActiveRecord::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
    class_option :model, :type => :boolean, :default => true, :desc=> "Create model"
    class_option :migration,  :type => :boolean, :default => true, :desc => 'Create migration file for current grid'
    class_option :controller,  :type => :boolean, :default => true, :desc => 'Create controller for current grid'
    class_option :routes,  :type => :boolean, :default => true, :desc => 'Config routes for current grid'
    class_option :views,  :type => :boolean, :default => true, :desc => 'Config views directory for current grid'

    def create_migration_file
      return unless options[:migration]
      migration_template "grid_migration.rb", "db/migrate/create_#{table_name}.rb"
    end

    def create_controller
      return unless options[:controller]
      template "controller.rb", "app/controllers/#{table_name}_controller.rb"
    end

    def create_screen
      template "screen.rb", "app/screens/#{underscored_name}_screen.rb"
    end

    def create_grid
      template "grid.rb", "app/grids/#{underscored_name}_grid.rb"
    end

    def create_model
      return unless options[:model]
      template "model.rb", "app/models/#{underscored_name}.rb" if options.model?
    end

    def add_route
      return unless options[:routes]
      route "resources :#{table_name}"
    end
    
    def create_view_directory
      return unless options[:views]
      empty_directory "app/views/#{table_name}"
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