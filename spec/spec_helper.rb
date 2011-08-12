ENV["RAILS_ENV"] ||= 'test'

require 'rails/all'
require 'rspec/rails'

require 'wulin_master'
require 'wulin_master/configuration'

RSpec.configure do |config|
  config.mock_with :rspec
end

