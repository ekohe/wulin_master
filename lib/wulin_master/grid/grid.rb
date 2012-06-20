require File.join(File.dirname(__FILE__), 'toolbar')
require File.join(File.dirname(__FILE__), 'toolbar_item')
require File.join(File.dirname(__FILE__), 'column')
require File.join(File.dirname(__FILE__), 'grid_options')
require File.join(File.dirname(__FILE__), 'grid_styling')
require File.join(File.dirname(__FILE__), 'grid_columns')
require File.join(File.dirname(__FILE__), 'grid_actions')
require File.join(File.dirname(__FILE__), 'grid_behaviors')
require File.join(File.dirname(__FILE__), 'grid_relation')
require File.join(File.dirname(__FILE__), 'grid_states')

module WulinMaster
  class Grid
    include GridOptions
    include GridStyling
    include GridColumns
    include GridActions
    include GridBehaviors
    include GridRelation
    include GridStates
    
    cattr_accessor :grids

    DEFAULT_CONFIG = {fill_window: true}

    # Grid has been subclassed
    def self.inherited(klass)
      self.grids ||= []
      self.grids << klass
      klass.init
    end

    # Class methods
    # -------------------
    class << self
      attr_reader :title, :model, :path
      attr_accessor :controller_class

      # Called when the grid is subclassed
      def init
        initialize_columns
        initialize_actions

        initialize_behaviors
        load_default_behaviors  # load default behaviors here rather than in application code

        initialize_options
        # default options
        cell_editable
        column_sortable

        initialize_styles
      end

      def title(new_title=nil)
        new_title ? @title = new_title : @title || self.to_s.gsub(/Grid/, "")
      end

      def model(new_model=nil)
        new_model ? @model = new_model : @model || self.title.singularize.try(:constantize)
      end

      def path(new_path=nil)
        new_path ? @path = new_path : @path || self.to_s.gsub(/Grid/, "").underscore.pluralize
      end
    end

    # Instance methods
    # --------------------
    attr_accessor :controller, :params, :custom_config, :toolbar

    def initialize(params={}, controller_instance=nil, config={})
      self.params = params
      self.controller = controller_instance
      self.custom_config = config

      # if not json request, it needs to initialize toolbar and configs, else, just assign the attributes like above
      if params[:format] != "json"
        # first apply default configs, then apply custom configs
        apply_default_config
        apply_custom_config unless self.custom_config.blank?

        initialize_toolbar
      end
    end

    # Grid Properties that can be overriden
    def title
      self.class.title || self.class.to_s.humanize
    end

    def model
      self.class.model
    end

    def path
      uri = URI.parse(self.class.path)
      uri.query = [uri.query, "grid=#{self.class.to_s}"].compact.join('&')
      uri.to_s
    end           
    
    def path_for_json(params)
      uri = URI.parse(self.path).dup
      uri.path << ".json"
      uri.query = [uri.query, CGI.unescape(params.to_query)].compact.join('&')
      uri.to_s
    end

    def name
      grid_name = self.class.to_s.sub('Grid', '').underscore
      screen_name = self.params[:screen].constantize.new.name if self.params[:screen]
      if screen_name.nil? or screen_name == grid_name
        grid_name
      else
        "#{grid_name}_in_#{screen_name}"
      end
    end

    # Helpers for SQL and Javascript generation
    # ----------
    def sql_columns
      self.columns.map(&:sql_names).compact.flatten.uniq.map(&:to_s)
    end

    def apply_filter(query, column_name, filtering_value)
      column = self.columns.find{|c| c.name.to_s == column_name.to_s} || self.columns.find{|c| c.foreign_key == column_name.to_s }
      if column and column.options[:filterable] != false
        column.apply_filter(query, filtering_value)
      else
        Rails.logger.info "Couldn't find column for #{column_name}, couldn't apply filter #{filtering_value}."
        query
      end
    end

    def apply_order(query, column_name, order_direction)
      column_name = column_name.split(".").last if column_name.include?(".")

      column = self.columns.find{|c| c.name.to_s == column_name or c.foreign_key == column_name }
      column ? column.apply_order(query, order_direction) : query
      
    end

    # Returns the includes to add to the query
    def includes
      self.columns.map{|col| col.includes}.flatten.uniq
    end

    # Returns the joins to add to the query
    def joins
      self.columns.map{|col| col.joins}.flatten.uniq
    end

    def arraify(objects)
      objects.collect do |object|
        self.columns.collect {|col| col.json(object) }
      end
    end

    def javascript_column_model
      @javascript_column_model = self.columns.collect(&:to_column_model).to_json
    end


    private

    def initialize_toolbar
      self.toolbar ||= Toolbar.new(name, self.toolbar_actions)
    end

    def apply_default_config
      DEFAULT_CONFIG.each do |k,v|
        apply_config(k,v)
      end
    end

    def apply_custom_config
      self.custom_config.each do |k,v|
        apply_config(k,v)
      end
    end

    # calling a config
    def apply_config(key, value)
      if self.class.respond_to?(key) and (arguments_count = self.class.method(key).arity) != 0    # if grid class respond to the config method and it is a writter method
        if arguments_count == 1
          self.class.send(key, value)
        elsif arguments_count == -1 or arguments_count == -2  # if this method accept options, pass the grid's params as options
          # when argument_count is -1, sometimes it can accept self.params (like :fill_window), sometimes it can't (like :title)
          begin
            self.class.send(key, value, self.params)
          rescue 
            self.class.send(key, value)
          end
        end
      end
    end
  end
end