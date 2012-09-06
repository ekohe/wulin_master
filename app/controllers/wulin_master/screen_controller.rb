module WulinMaster
  class ScreenController < ApplicationController
    prepend_view_path File.join(File.dirname(__FILE__), '..', '..', 'views')

    respond_to :html, :json

    rescue_from ActionView::MissingTemplate, with: :render_index

    include WulinMaster::Actions

    # ----------------------------- Meta Class Methods ----------------------------------
    class << self
      attr_accessor :screen_classes, :grid_class, :callbacks
      
      def controller_for_screen(*args)
        self.screen_classes = args
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
    end

    # ???
    def self.current_user
      current_user
    end

    # -------------------------------- Instance Methods -------------------------------
    # Returns and initializes if necessary a screen object
    def screen
      return @screen if defined?(@screen)

      screen_class = params[:screen].classify.safe_constantize.presence || self.class.screen_classes.first.presence
      # if params[:screen]
      #   if self.class.screen_classes.find {|sc| params[:screen].constantize <= sc }   # Check if subclass or class itself.
      #     params[:screen].classify.safe_constantize
      #   else
      #     raise "Can't find a proper screen for the controller"
      #   end
      # else
      #   self.class.screen_classes.first
      # end

      @screen = screen_class.new(params, self) if screen_class
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

    def render_index
      render '/index', :layout => (request.xhr? ? false : 'application')
    end
  end
end

