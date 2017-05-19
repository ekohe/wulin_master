require 'wulin_master/engine' if defined?(Rails)

require 'haml'
require 'haml-rails'
require 'jquery-rails'
require 'jquery-ui-rails'
require 'coffee-rails'
require 'sass-rails'
require 'responders'

module WulinMaster
  @javascripts = ['application.js']
  @stylesheets = ['application.css']

  def self.add_javascript(script)
    @javascripts << script
  end

  def self.prepend_javascript(script)
    @javascripts.unshift script
  end

  def self.prepend_stylesheet(css)
    @stylesheets.unshift css
  end

  def self.add_stylesheet(css)
    @stylesheets << css
  end

  def self.javascripts
    @javascripts
  end

  def self.stylesheets
    @stylesheets
  end

  def self.default_datetime_format=(new_value)
    @default_datetime_format = new_value
  end

  def self.default_datetime_format
    @default_datetime_format || :db
  end
end

require 'wulin_master/utilities/utilities'
require 'wulin_master/configuration'
require 'wulin_master/extension'
require 'wulin_master/actions'
require 'wulin_master/menu/menu'
require 'wulin_master/screen/screen'
require 'wulin_master/components/component'
require 'wulin_master/components/grid/grid'
require 'wulin_master/components/panel/panel'

WulinMaster.prepend_javascript 'master/master.js'
WulinMaster.prepend_stylesheet 'master.css'

Time::DATE_FORMATS[:no_seconds] = "%d/%m/%Y %H:%M"
Time::DATE_FORMATS[:date] = "%d/%m/%Y"
Time::DATE_FORMATS[:time] = "%H:%M"
WulinMaster.default_datetime_format = :no_seconds
