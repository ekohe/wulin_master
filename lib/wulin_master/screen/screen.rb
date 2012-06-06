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

    # ---------------------- metaclass, define some DSL methods -------------------------------
    class << self
      #alias_method :all, :screens
      attr_reader :title, :path, :grid_configs
      attr_accessor :controller_class

      def title(new_title=nil)
        new_title ? @title = new_title : @title || self.to_s.gsub(/Screen/, "")
      end

      def path(new_path=nil)
        new_path ? @path = new_path : @path || self.title.tableize
        # TODO
        # in last circle of refactoring, the screen path can be the same-named action path of screens_controller
      end

      # Add a grid config to a screen
      def grid(klass, options={})        
        @grid_configs ||= []
        @grid_configs << {class: klass}.merge(options) if klass
      end
    end

    # -------------------------------- Instance methods ---------------------------------------
    attr_accessor :grids, :controller, :params
    
    def initialize(params, controller_instance)
      @controller = controller_instance
      @params = params
      @grids = []
      self.class.grid_configs.each do |grid_config|
        @grids << grid_config[:class].new(params, controller_instance, grid_config)
      end unless self.class.grid_configs.blank?
    end
    
    def path
      # This should be better put together. What if there's already a parameter in the path? that would break
      self.class.path + "?screen=#{self.class.to_s}" 
    end
    
    def name
      self.class.name.sub(/Screen$/, "").underscore
    end
    
    # Security
    def authorized?(user)
      true
    end
    
    alias_method :authorize_create?, :authorized?
    alias_method :authorize_update?, :authorized?
    alias_method :authorize_destroy?, :authorized?
  end
end