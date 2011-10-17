module WulinMaster
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    
    def copy_homecontroller
      copy_file 'homepage_controller.rb', "app/#{WulinMaster::FOLDER_NAME}/controllers/homepage_controller.rb"
    end
    
    def add_route
      route "root :to => 'homepage#index'"
    end
  end
end
