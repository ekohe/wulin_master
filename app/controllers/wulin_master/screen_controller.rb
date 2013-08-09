module WulinMaster

  module Variables
    def screen
      @screen ||= begin
        if params[:screen].present?
          if screen_class = params[:screen].classify.safe_constantize
            screen_class.new(self)
          else
            raise "Can't find a proper screen for the controller"
          end
        else
          self.class.screen_classes.first.new(self)
        end
      end
    end

    def grid
      @grid ||= begin
        if params[:grid]
          screen.grids.find {|grid| grid.class.name == params[:grid]}
        else
          screen.grids.find {|grid| grid.model.model_name.plural == controller_name}
        end || screen.grids.first
      end
    end

    def components
      @components ||= screen.components
    end
  end


  class ScreenController < ApplicationController
    include WulinMaster::Variables
    include WulinMaster::Actions

    prepend_view_path File.join(File.dirname(__FILE__), '..', '..', 'views')
    respond_to :html, :json
    rescue_from ActionView::MissingTemplate, with: :render_index

    helper_method :screen, :grid, :components

    class << self
      attr_accessor :screen_classes, :grid_class, :callbacks

      def controller_for_screen(*args)
        self.screen_classes = args
      end

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
    end

    private

      def render_index
        render '/index', :layout => (request.xhr? ? false : 'application')
      end
  end
end

