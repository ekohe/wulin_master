module WulinMaster
  class ScreenController < ApplicationController
    prepend_view_path File.join(Rails.root, 'app', WulinMaster.config.asset_folder_name, 'views')
    prepend_view_path File.join(File.dirname(__FILE__), '..', '..', 'views')

    class << self
      def controller_for_screen(klass)
        self.screen_class = klass
        klass.controller_class = self
        load_actions
      end

      def controller_for_grid(klass)
        self.grid_class = klass
        klass.controller_class = self
        @callbacks = {}
        load_actions
      end

      attr_accessor :screen_class, :grid_class, :callbacks

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

      def find_callbacks(name)
        @callbacks[name] 
      end
      
      def callbacks
        @callbacks
      end
      
      # Load actions
      def load_actions
        self.send(:include, WulinMaster::Actions)
      end
    end

    # Returns and initializes if necessary a screen object
    def screen
      return @screen if defined?(@screen)
      screen_class = self.class.screen_class
      if params[:screen]
        begin
          if params[:screen].constantize <= self.class.screen_class  # Check if subclass or class itself.
            screen_class = params[:screen].constantize
          end
        rescue Exception => e
        end
      end
      
      @screen = screen_class.new(params, self)
    end

    # Returns and initializes if necessary a grid object
    def grid
      return @grid if defined?(@grid)
      grid_class = self.class.grid_class

      if params[:grid]
        begin
          if params[:grid].constantize <= self.class.grid_class  # Check if subclass or class itself.
            grid_class = params[:grid].constantize
          end
        rescue Exception => e
        end
      end
      Rails.logger.info "Grid is a #{grid_class}"
      @grid = grid_class.new(params, self)
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
    
    def fire_callbacks(name)
      return unless self.class.callbacks
      cbs = self.class.find_callbacks(name)

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

