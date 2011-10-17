module WulinMaster
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    def copy_homecontroller
      copy_file 'homepage_controller.rb', "app/controllers/homepage_controller.rb"
    end
    
    def copy_config_file
      copy_file 'wulin_master.rb', "config/initializers/wulin_master.rb"
    end
    
    def add_route
      route "root :to => 'homepage#index'"
    end
  end
end
