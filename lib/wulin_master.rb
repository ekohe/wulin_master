module WulinMaster
  @javascripts = []
  @stylesheets = []

  def self.app_title
    APP_TITLE || "Empty App"
  end

  def self.add_javascript(script)
    @javascripts << script
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

WulinMaster::add_javascript 'master.js'
WulinMaster::add_stylesheet 'master.css'

Time::DATE_FORMATS[:no_seconds] = "%Y-%m-%d %H:%M"
Time::DATE_FORMATS[:date] = "%Y-%m-%d"
Time::DATE_FORMATS[:time] = "%H:%M"
WulinMaster.default_datetime_format = :no_seconds

require 'wulin_master/screen/screen'
require 'wulin_master/controller/screen_controller'
require 'wulin_master/controller/home_controller'
require 'wulin_master/menu/menu'