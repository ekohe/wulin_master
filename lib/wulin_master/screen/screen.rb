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
      @path = new_path if new_path
      @path
    end

    def self.grid_classes
      @grid_classes
    end

    def self.grid(klass)
      #@grid_context = klass.grid_context
      @grid_classes ||= []
      @grid_classes << klass

      # magic here
      #klass.config_block.call if klass.config_block

      #@grid_context = nil
    end
    
    def initialize(controller_instance)
      self.controller = controller_instance
      @grids = []
      self.class.grid_classes.each do |grid_class|
        @grids << grid_class.new(controller_instance)
      end
    end
    
    attr_accessor :grids, :controller
  end
end