require File.join(File.dirname(__FILE__), 'column')
require File.join(File.dirname(__FILE__), 'grid')

module WulinMaster
  class Screen
    cattr_reader :screens
    class << self
      alias_method :all, :screens
    end
    @@screens = []

    def self.inherited(subclass)
      @grids = []
      @title = false
      @path = ''
      @@screens << subclass unless @@screens.include?(subclass)

      Rails.logger.info "Screen #{subclass} loaded"
    end

    # Sets or return a title for the grid or the screen depending on the context
    def self.title(new_title=nil)
      if @grid_context.nil?
        @title = new_title if new_title # sets the new title if there's any
        @title || self.to_s.gsub(/Screen/, "")
      else
        @grid_context.title(new_title)
      end
    end

    def self.path(new_path=nil)
      if @grid_context
        @grid_context.path(new_path)
      else
        @path = new_path unless new_path == nil
        @path
      end
    end

    def self.grids
      @grids
    end

    def self.grid(klass)
      @grid_context = klass.grid_context
      @grids ||= []
      @grids << @grid_context
      
      # magic here
      klass.screen_context = self
      klass.config_block.call if klass.config_block
      
      @grid_context = nil
    end

    # Grid setup
    def self.column(name, options={})
      return unless @grid_context
      @grid_context.column(name, options)
    end

    class << self
      [:base_model, :height, :width].each do |attribute|
        define_method attribute do |new_value|
          return unless @grid_context
          @grid_context.send(attribute, new_value)    
        end
      end  
    end

    def self.fill_window
      return unless @grid_context
      @grid_context.fill_window
    end

    def self.add_to_toolbar(title, options={})
      return unless @grid_context
      @grid_context.add_to_toolbar(title, options)
    end

    # Not used if you have the autoload_paths setup in application.rb to %W(#{config.root}/app/screens)
    def self.load_all
      Dir.glob("#{Rails.root}/app/screens/*.rb").each do |file|
        require file
      end
    end
  end
end