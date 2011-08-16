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
end






