module WulinMaster  
  def self.configure(configuration=WulinMaster::Configuration.new)
    yield configuration if block_given?
    @@configuration = configuration
  end
  
  def self.configuration
    @@configuration ||= WulinMaster::Configuration.new
  end
  
  class Configuration
    # render excel
    attr_accessor :app_title
    
    def initialize
      self.app_title = "Empty App"
    end
  end
end
