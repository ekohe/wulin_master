require 'rails/generators'
require 'rails/generators/active_record'

module WulinMaster
  class ScreenAndGridGenerator < ActiveRecord::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    #argument :columns, :type => :array, :default => [], :banner => "column column"
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
      template "controller.rb", "app/#{WulinMaster.config.asset_folder_name}/controllers/#{table_name}_controller.rb"
    end

    def create_screen
      template "screen.rb", "app/#{WulinMaster.config.asset_folder_name}/screens/#{underscored_name}_screen.rb"
    end

    def create_grid
      template "grid.rb", "app/#{WulinMaster.config.asset_folder_name}/grids/#{underscored_name}_grid.rb"
    end

    def create_model
      return unless options[:model]
      template "model.rb", "app/#{WulinMaster.config.asset_folder_name}/models/#{underscored_name}.rb" if options.model?
    end

    def add_route
      return unless options[:routes]
      route "resources :#{table_name}"
    end
    
    def create_view_directory
      return unless options[:views]
      empty_directory "app/#{WulinMaster.config.asset_folder_name}/views/#{table_name}"
    end
    
    def create_panels_directory
      empty_directory "app/#{WulinMaster.config.asset_folder_name}/panels"
    end
    
    def create_action_partials_directory
      empty_directory "app/#{WulinMaster.config.asset_folder_name}/views/action_partials"
    end
    
    def create_panel_partials_directory
      empty_directory "app/#{WulinMaster.config.asset_folder_name}/views/panel_partials"
    end
    
    def add_autoload_paths
      application '  config.autoload_paths += %W(#{Rails.root}/app/' + WulinMaster.config.asset_folder_name + '/grids)'
      application '  config.autoload_paths += %W(#{Rails.root}/app/' + WulinMaster.config.asset_folder_name + '/screens)'
      application '  config.autoload_paths += %W(#{Rails.root}/app/' + WulinMaster.config.asset_folder_name + '/controllers)'
      application '  config.autoload_paths += %W(#{Rails.root}/app/' + WulinMaster.config.asset_folder_name + '/models)'
      application '  config.autoload_paths += %W(#{Rails.root}/app/' + WulinMaster.config.asset_folder_name + '/panels)'
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