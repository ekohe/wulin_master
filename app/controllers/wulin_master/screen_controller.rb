require 'wulin_master/utilities/variables'
module WulinMaster
  class ScreenController < ApplicationController
    include WulinMaster::Menuable
    include WulinMaster::Actions

    prepend_view_path File.join(File.dirname(__FILE__), '..', '..', 'views')
    respond_to :html, :json
    rescue_from ActionView::MissingTemplate, with: :render_index

    helper_method :screen, :grid, :components

    def self.inherited(subclass)
      subclass.define_menu
    end

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
      render '/index', :layout => (request.xhr? ? false : 'application'), :locals => {xhr: request.xhr?}
    end
  end
end
