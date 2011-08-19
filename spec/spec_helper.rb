require 'rubygems'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require 'rails/all'
  require 'rspec/rails'
  RSpec.configure do |config|
    config.mock_with :rspec
  end
end

Spork.each_run do
  require 'wulin_master'
  require 'wulin_master/configuration'
  require 'wulin_master/menu/menu'
  require 'wulin_master/screen/column'
  require 'wulin_master/screen/grid'
  require 'wulin_master/screen/grid_config'
  require 'wulin_master/screen/screen'
  require 'wulin_master/screen/toolbar'
  require 'wulin_master/screen/toolbar_item'
end






