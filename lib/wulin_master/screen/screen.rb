# frozen_string_literal: true

module WulinMaster
  class Screen
    cattr_accessor :screens

    # subclass inherited
    def self.inherited(subclass)
      # add new subclass screen to screens pool
      self.screens ||= []
      self.screens << subclass unless self.screens.include?(subclass)

      # ???
      subclass.send :include, Rails.application.routes.url_helpers
      Rails.logger.info "Screen #{subclass} loaded"
    end

    class << self
      # alias_method :all, :screens
      attr_reader :grid_configs, :panel_configs, :components_pool
      attr_accessor :controller_class

      def title(new_title = nil)
        new_title.nil? ? (@title || to_s.gsub(/Screen/, "")) : (@title = new_title)
      end

      def path(new_path = nil)
        new_path ? @path = new_path : @path || to_s.gsub(/Screen/, "").underscore.pluralize
        # TODO
        # in last circle of refactoring, the screen path can be the same-named action path of screens_controller
      end

      # Add a grid config to a screen
      def grid(klass, options = {})
        @components_pool ||= []
        @grid_configs ||= []
        if klass
          @components_pool << klass
          @grid_configs << {class: klass}.merge(options)
          options.each do |k, v|
            klass.apply_config(k, v, screen: name)
          end
        end
      end

      # Add a panel config to a screen
      def panel(klass, options = {})
        @components_pool ||= []
        @panel_configs ||= []
        if klass
          @components_pool << klass
          @panel_configs << {class: klass}.merge(options)
          options.each do |k, v|
            klass.apply_config(k, v, screen: name)
          end
        end
      end
    end

    attr_accessor :controller, :params, :current_user

    def initialize(controller_instance = nil)
      @controller = controller_instance
      @params = controller_instance.try(:params)
      @current_user = controller_instance.try(:current_user)
    end

    def grids
      return @grids if defined?(@grids)
      @grids = []
      self.class.grid_configs&.each do |grid_config|
        grid_class = grid_config[:class]
        config = grid_config.reject { |k, _v| k == :class }
        @grids << grid_class.new(self, config) if grid_class
      end
      @grids
    end

    def panels
      return @panels if defined?(@panels)

      @panels = []
      self.class.panel_configs&.each do |panel_config|
        panel_class = panel_config[:class]
        config = panel_config.reject { |k, _v| k == :class }
        @panels << panel_class.new(self, config) if panel_class
      end
      @panels
    end

    def components
      @components ||= begin
        grids_and_panels = grids + panels
        grids_and_panels.sort_by! { |e| self.class.components_pool.index(e.class) }
        grids_and_panels.select! { |x| x.class.name == params[:grid] } if params[:grid].present?
        grids_and_panels
      end
    end

    def path
      # This should be better put together. What if there's already a parameter in the path? that would break
      self.class.path + "?screen=#{self.class}"
    end

    def name
      WulinMaster::Utilities.get_screen_name(self.class.name)
    end

    # Security
    def authorized?(_user = nil)
      true
    end

    alias authorize_create? authorized?
    alias authorize_update? authorized?
    alias authorize_destroy? authorized?
  end
end
