require "rails"
require 'wulin_master/mapper'
module WulinMaster

  class Engine < Rails::Engine
    engine_name :wulin_master 
    initializer "add assets to precompile" do |app|
       app.config.assets.precompile += %w( master/master.js master.css )
    end
  end
end