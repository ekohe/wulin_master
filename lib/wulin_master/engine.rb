# frozen_string_literal: true

require "rails"
require 'wulin_master/mapper'

module WulinMaster
  class Engine < Rails::Engine
    initializer "add assets to precompile" do |app|
      app.config.assets.precompile += %w[master/master.js master.css]
    end

    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end
  end
end
