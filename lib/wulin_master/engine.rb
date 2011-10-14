require "wulin_master"
require "rails"

module WulinMaster

  class Engine < Rails::Engine
    engine_name :wulin_master 
    config.before_configuration do |app|
      app.config.autoload_paths << "#{Rails.root}/app/#{WulinMaster::FOLDER_NAME}/grids"
      app.config.autoload_paths << "#{Rails.root}/app/#{WulinMaster::FOLDER_NAME}/screens"
      app.config.autoload_paths << "#{Rails.root}/app/#{WulinMaster::FOLDER_NAME}/controllers"
      app.config.autoload_paths << "#{Rails.root}/app/#{WulinMaster::FOLDER_NAME}/models"
      # app.configpaths["app/views"] << "#{Rails.root}/app/#{WulinMaster::FOLDER_NAME}/views"
    end
  end
end