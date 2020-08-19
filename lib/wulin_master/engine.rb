# frozen_string_literal: true

require "rails"
require 'wulin_master/mapper'

module WulinMaster
  class Engine < Rails::Engine
    initializer :append_migrations do |app|
      config.paths["db/migrate"].expanded.each do |expanded_path|
        app.config.paths["db/migrate"] << expanded_path
      end
    end
  end
end
