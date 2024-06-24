# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)
require "wulin_master/version"

Gem::Specification.new do |s|
  s.name = "wulin_master"
  s.version = WulinMaster::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Ekohe"]
  s.email = ["info@ekohe.com"]
  s.homepage = "http://rubygems.org/gems/wulin_master"
  s.summary = "WulinMaster is a grid plugin base on Ruby on Rails and SlickGrid."
  s.description = 'WulinMaster is a grid plugin base on Ruby on Rails and SlickGrid. It provides powerful generator
  and other tools to make grids easy to build as well as flexible configurations.'

  s.files = `git ls-files`.split("\n")
  s.test_files = Dir["spec/**/*"]
  s.executables = []
  s.require_paths = ["lib"]

  s.add_dependency "coffee-rails"
  s.add_dependency "haml-rails"
  s.add_dependency "jquery-rails"
  s.add_dependency "jquery-ui-rails", "~> 7.0.0"
  s.add_dependency "material_icons", "~> 2.2.1"
  s.add_dependency "materialize-sass", "~> 1.0.0"
  s.add_dependency "rails"
  s.add_dependency "responders"
  s.add_dependency "sass-rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "cucumber-rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "factory_bot"
  s.add_development_dependency "faker", "~> 2.1.2"
  s.add_development_dependency "generator_spec"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "pg", "~> 0.18"
  s.add_development_dependency "poltergeist"
  s.add_development_dependency "puma"
  s.add_development_dependency "rspec-rails"
end
