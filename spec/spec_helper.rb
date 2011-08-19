require 'rubygems'
require 'spork'

Spork.prefork do
  ENV["RAILS_ENV"] ||= 'test'
  require 'rails/all'
  require 'rspec/rails'
  
  RSpec.configure do |config|
    config.mock_with :rspec
  end
  
  # define url helper for testing
  require 'ostruct'
  module ActionController::UrlFor
    def _routes
      helpers = OpenStruct.new
      helpers.url_helpers = Module.new
      helpers
    end
  end
  
  # create a dummy rails app
  class TestApp < Rails::Application
    config.root = File.dirname(__FILE__)
  end
  Rails.application = TestApp
  
  TestApp.routes.draw do
    resources :countries
  end
  
  module Rails
    def self.root
      @root ||= File.expand_path("../../tmp/rails", __FILE__)
    end
  end
  
  class ApplicationController < ActionController::Base
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






