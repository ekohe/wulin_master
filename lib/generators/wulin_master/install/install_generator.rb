# frozen_string_literal: true

module WulinMaster
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)

    def copy_application_controller
      remove_file 'app/controllers/application_controller.rb'
      copy_file 'application_controller.rb', 'app/controllers/application_controller.rb'
    end

    def copy_homepage_controller
      copy_file 'homepage_controller.rb', 'app/controllers/homepage_controller.rb'
    end

    def copy_config_file
      copy_file 'wulin_master.rb', 'config/initializers/wulin_master.rb'
    end

    def create_panels_directory
      empty_directory 'app/panels'
    end

    def create_action_partials_directory
      empty_directory 'app/views/action_partials'
    end

    def create_panel_partials_directory
      empty_directory 'app/views/panel_partials'
    end

    def add_route
      route "root to: 'homepage#index'"
    end
  end
end
