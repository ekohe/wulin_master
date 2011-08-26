require 'rails/generators/active_record'

module WulinMaster
  class ScreenAndGridGenerator < ActiveRecord::Generators::Base
    Rails::Generators::Migration
    source_root File.expand_path('../templates', __FILE__)
    #argument :columns, :type => :array, :default => [], :banner => "column column"
    argument :attributes, :type => :array, :default => [], :banner => "field:type field:type"
    class_option :model, :type => :boolean, :default => true, :description => "Create model"
    class_option :indexes, :type => :boolean, :default => true, :desc => "Add indexes for references and belongs_to columns"

    def create_migration_file
      migration_template "migration.rb", "db/migrate/create_#{table_name}.rb"
    end

    def create_controller
      template "controller.rb", "app/controllers/#{table_name}_controller.rb"
    end

    def create_screen
      template "screen.rb", "app/screens/#{underscored_name}_screen.rb"
    end

    def create_grid
      template "grid.rb", "app/grids/#{underscored_name}_grid.rb"
    end

    def create_model
      template "model.rb", "app/models/#{underscored_name}.rb" if options.model?
    end

    def add_route
      route "resources :#{table_name}"
    end

    private

    def underscored_name
      name.underscore
    end

    def class_name
      name.classify
    end

    def human_name
      name.underscore.humanize
    end

  end
end