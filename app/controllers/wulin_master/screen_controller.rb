module WulinMaster
  class ScreenController < ApplicationController
    prepend_view_path File.join(Rails.root, 'app', WulinMaster.config.asset_folder_name, 'views')
    prepend_view_path File.join(File.dirname(__FILE__), '..', '..', 'views')

    respond_to :html, :json

    # When the controller has been subclassed
    # def self.inherited(klass)

    # end

    # ----------------------------- Meta Class Methods ----------------------------------
    class << self
      attr_accessor :screen_classes, :grid_class, :callbacks
      
      def controller_for_screen(*args)
        self.screen_classes = args
        include_actions
      end

      # Callbacks
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
      def include_actions
        self.send(:include, WulinMaster::Actions)
      end
    end

    # ???
    def self.current_user
      current_user
    end

    # -------------------------------- Instance Methods -------------------------------
    # Returns and initializes if necessary a screen object
    def screen
      return @screen if defined?(@screen)

      screen_class = if params[:screen]
        #if self.class.screen_classes.find {|sc| params[:screen].constantize <= sc }   # Check if subclass or class itself.
          params[:screen].constantize
        # else
        #   raise "Can't find a proper screen for the controller"
        # end
      else
        self.class.screen_classes.first
      end

      @screen = screen_class.new(params, self)
    end

    # Returns and initializes if necessary a grid object
    def grid
      @grid = if params[:grid]
        screen.grids.find {|grid| grid.class.to_s == params[:grid]}
      else
        screen.grids.find {|grid| grid.model.to_s.underscore.pluralize == controller_name}
      end
      # if can't find, return the first grid
      @grid || screen.grids.first
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

