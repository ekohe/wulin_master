require File.join(File.dirname(__FILE__), 'column')
require File.join(File.dirname(__FILE__), 'grid')

module WulinMaster
  class Screen
    cattr_reader :screens
    class << self
      alias_method :all, :screens
      attr_accessor :grids, :title, :path
    end
    @@screens = []

    def self.inherited(subclass)
      subclass.grids = []
      subclass.title = nil
      subclass.path = "/" + subclass.name.sub(/Screen$/, "").tableize
      @@screens << subclass unless @@screens.include?(subclass)

      Rails.logger.info "Screen #{subclass} loaded"
    end

    # Sets or return a title for the grid or the screen depending on the context
    def self.title(new_title=nil)
      @title = new_title if new_title # sets the new title if there's any
      @title || self.to_s.gsub(/Screen/, "")
    end
    
    def self.path(new_path=nil)
      @path = new_path unless new_path == nil
      @path
    end

    def self.grids
      @grids
    end

    def self.grid(klass)
      @grid_context = klass.grid_context
      @grids ||= []
      @grids << @grid_context
      
      # magic here
      klass.config_block.call if klass.config_block
      
      @grid_context = nil
    end

    # Not used if you have the autoload_paths setup in application.rb to %W(#{config.root}/app/screens)
    def self.load_all
      Dir.glob("#{Rails.root}/app/screens/*.rb").each do |file|
        require file
      end
    end
  end
end