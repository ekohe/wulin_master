# frozen_string_literal: true

require 'dartsass-rails'

# Wulin Master assets configuration for Propshaft
Rails.application.configure do
  # Add builds directory to asset paths
  config.assets.paths << Rails.root.join("app/assets/builds")
  
  # Add assets to precompile
  config.assets.precompile += %w[
    *.woff
    *.woff2
  ]
  
  Rails.application.config.dartsass.builds = {
    "application.sass"  => "application.css"
  }
  
  # Add node_modules to Sass load path for npm packages
  Rails.application.config.dartsass.build_options << "--load-path=node_modules"
end
