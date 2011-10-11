require "wulin_master"
require "rails"

module WulinMaster
  FOLDER_NAME = 'wulin_master'
  
  class Engine < Rails::Engine
    engine_name :wulin_master    
    config.autoload_paths << "app/#{WulinMaster::FOLDER_NAME}/controllers"
    config.autoload_paths << "app/#{WulinMaster::FOLDER_NAME}/models"
    config.autoload_paths << "app/#{WulinMaster::FOLDER_NAME}/grids"
    config.autoload_paths << "app/#{WulinMaster::FOLDER_NAME}/screens"
  end
end