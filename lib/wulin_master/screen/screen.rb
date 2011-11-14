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
      subclass.send :include, Rails.application.routes.url_helpers
      Rails.logger.info "Screen #{subclass} loaded"
    end

    class_attribute :_title, :_path, :_grid_classes

    class << self

      # Sets or return a title for the grid or the screen depending on the context
      def title(new_title=nil)
        self._title = new_title if new_title # sets the new title if there's any
        self._title || self.to_s.gsub(/Screen/, "")
      end

      def path(new_path=nil)
        self._path = new_path if new_path
        self._path
      end

      def grid_classes
        self._grid_classes
      end

      # Add a grid to a screen
      def grid(klass)
        self._grid_classes ||= []
        self._grid_classes << klass
      end
    end
    
    
    def initialize(params, controller_instance)
      self.controller = controller_instance
      self.params = params
      @grids = []
      self.class.grid_classes.each do |grid_class|
        @grids << grid_class.new(params, controller_instance)
      end
    end
    
    def path
      self.class.path
    end
    
    attr_accessor :grids, :controller, :params
  end
end