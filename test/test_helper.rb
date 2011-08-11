ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] ||= File.join(File.dirname(__FILE__), "../../../..")

require 'rubygems'
require 'test/unit'
require 'active_support'
require File.expand_path(File.join(ENV['RAILS_ROOT'], 'config/environment.rb'))

# for generators
require "rails/generators/test_case"