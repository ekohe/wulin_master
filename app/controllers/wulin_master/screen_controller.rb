module WulinMaster
  class ScreenController < ApplicationController
    self.view_paths = [File.join(Rails.root, 'app', 'views'), File.join(Rails.root, 'app', WulinMaster.config.asset_folder_name, 'views'), File.join(File.dirname(__FILE__), '..', '..', 'views')]

    class << self
      def controller_for_screen(klass)
        self.screen_class = klass
        load_actions
      end

      def controller_for_grid(klass)
        self.grid_class = klass
        self.grid_class.controller_class = self
        @callbacks = {}
        load_actions
      end
      
      # Where is this used?
      def index_path
        "/#{self.to_s.underscore.downcase.gsub(/_controller/, '')}"
      end

      attr_accessor :screen_class, :grid_class

      # Callbacks
      #

      def add_callback(name, method_name=nil)
        @callbacks ||= {}
        @callbacks[name] ||= []
        if block_given?
          @callbacks[name] << lambda { yield }
        else
          @callbacks[name] << method_name
        end
      end

      def callbacks(name=nil)
        name ? @callbacks[name] : @callbacks
      end
    end

    # Returns and initializes if necessary a screen object
    def screen
      return @screen if defined?(@screen)
      @screen = self.class.screen_class.new(self)
    end

    # Returns and initializes if necessary a grid object
    def grid
      return @grid if defined?(@grid)
      @grid = self.class.grid_class.new(self)
    end
    
    def self.current_user
      current_user
    end

    def render_grid(grid_name)
      return "Grid not found '#{grid_name}'" unless screen.grids.map(&:name).include?(grid_name.to_sym)
      grid = screen.grids.find {|grid| grid.name == grid_name}
      grid.render
    end
    
    private

    # Load actions
    def self.load_actions
      self.send(:include, WulinMaster::Actions)
    end
    
    def fire_callbacks(name)
      return unless self.class.callbacks
      cbs = self.class.callbacks(name)

      return if cbs.blank?
      cbs.each do |cb|
        if cb.class == Proc
          cb.call
        else
          self.send(cb) if self.respond_to?(cb)
        end
      end
    end
  end
end

