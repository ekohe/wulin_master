# -*- encoding: utf-8 -*-
module WulinMaster  
  def self.configure(configuration=WulinMaster::Configuration.new)
    yield configuration if block_given?
    @@configuration = configuration
  end
  
  def self.config
    @@configuration ||= WulinMaster::Configuration.new
  end
  
  class Configuration
    attr_accessor :app_title, :app_title_height, :asset_folder_name
    
    def initialize
      self.app_title = 'Undefined App'
      self.app_title_height = '42px'
      self.asset_folder_name = 'wulin_master'
    end
  end
end
