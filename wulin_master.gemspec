# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "wulin_master/version"

Gem::Specification.new do |s|
  s.name        = "wulin_master"
  s.version     = WulinMaster::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Ekohe']
  s.email       = ['info@ekohe.com']
  s.homepage    = 'http://rubygems.org/gems/wulin_master'
  s.summary     = 'WulinMaster is a framework'
  s.description = 'WulinMaster is a framework'

  s.rubyforge_project = "wulin_master"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = Dir['spec/**/*']
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'rails', '~> 5.1.4'
  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'haml-rails'
  s.add_dependency 'coffee-rails'
  s.add_dependency 'sass-rails'
  s.add_dependency 'responders'
  s.add_dependency 'materialize-sass'
  s.add_dependency 'material_icons'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'spring'
  s.add_development_dependency 'spring-commands-rspec'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'generator_spec'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'cucumber-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'factory_girl'
  s.add_development_dependency 'faker'
end
