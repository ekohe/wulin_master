# frozen_string_literal: true

require "rails"
require 'wulin_master/mapper'

module WulinMaster
  class Engine < Rails::Engine
    # Propshaft configuration
    initializer "wulin_master.assets", after: :append_assets_path, group: :all do |app|      
      if defined?(Propshaft)
        Rails.application.config.assets.paths << root.join("app", "assets", "stylesheets")
        Rails.application.config.assets.paths << root.join("app", "assets", "javascripts")
      end

      app.config.assets.precompile += %w( dropzone.min.js dropzone.min.css )
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end
  end
end
