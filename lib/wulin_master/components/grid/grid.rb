require 'wulin_master/components/grid/toolbar'
require 'wulin_master/components/grid/column'
require 'wulin_master/components/grid/grid_options'
require 'wulin_master/components/grid/grid_columns'
require 'wulin_master/components/grid/grid_actions'
require 'wulin_master/components/grid/grid_behaviors'
require 'wulin_master/components/grid/grid_relation'
require 'wulin_master/components/grid/grid_states'
require 'wulin_master/components/grid/grid_dynamic_edit_form'

module WulinMaster
  class Grid < Component
    include GridOptions
    include GridColumns
    include GridActions
    include GridBehaviors
    include GridRelation
    include GridStates
    include GridDynamicEditForm
    
    cattr_accessor :grids
    class_attribute :_model, :_path, :titles_pool

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

        apply_default_config
      end

      # dispatch some default configs to config pools
      def apply_default_config
        DEFAULT_CONFIG.each do |k,v|
          apply_config(k,v)
        end if DEFAULT_CONFIG.is_a?(Hash)
      end

      def model(new_model=nil)
        new_model ? (self._model = new_model) : (self._model || self.title.singularize.try(:constantize))
      end

      def path(new_path=nil)
        new_path ? (self._path = new_path) : (self._path || model.table_name || self.to_s.gsub(/Grid/, "").underscore.pluralize)
      end

      # title setter and getter
      def title(new_title=nil, options={})
        self.titles_pool ||= {}
        screen = options[:screen] 
        if new_title 
          screen ? self.titles_pool[screen] = new_title : self.titles_pool[:_common] = new_title
        else
          self.titles_pool[screen] || self.titles_pool[:_common] || self.to_s.gsub(/Grid/, "")
        end
      end
    end

    # Instance methods
    # --------------------
    attr_accessor :toolbar, :virtual_sort_column, :virtual_filter_columns

    def initialize(params={}, screen_instance=nil, controller_instance=nil, config={})
      super

      if params[:no_render]     # if no_render, skip the config applying 
        return true
      elsif params[:format] != 'json'   # if format not json (screen request) it needs to initialize toolbar and styling configs
        # apply_default_config DEFAULT_CONFIG
        # apply_custom_config
        initialize_toolbar(controller_instance.current_user)
      else    # else, only need to apply custom configs without styling (like grid relation configs)
        # apply_custom_config_without_styling
      end
    end
    
    def virtual_filter_columns
      @virtual_filter_columns ||= []
    end

    # Grid Properties that can be overriden
    def title
      self.class.title(nil, self.params)
    end

    def model
      self.class.model
    end

    def model_columns
      @model_columns ||= model.column_names
    end

    def path
      uri = URI.parse(self.class.path)
      uri.query = [uri.query, "grid=#{self.class.to_s}"].compact.join('&')
      uri.to_s
    end           
    
    def path_for_json(params)
      uri = URI.parse(self.path).dup
      uri.path << ".json"
      uri.query = [uri.query, params.to_query].compact.join('&')
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

    def apply_filter(query, column_name, filtering_value, filtering_operator)
      if column = find_filter_column_by_name(column_name)
        if column.filterable?
          column.apply_filter(query, filtering_value, filtering_operator)
        else
          if column.reflection
            self.virtual_filter_columns << ["#{column.options[:through] || column.name}.#{column.option_text_attribute}", filtering_value, filtering_operator]
          else
            self.virtual_filter_columns << [column_name, filtering_value, filtering_operator]
          end
          query
        end
      else
        self.virtual_filter_columns << [column_name, filtering_value, filtering_operator]
        # Rails.logger.info "Couldn't find column for #{column_name}, couldn't apply filter #{filtering_value}."
        query
      end
    end

    def apply_order(query, column_name, order_direction)
      column_name = column_name.split(".").last if column_name.include?(".")
      
      if column = find_sort_column_by_name(column_name)
        if column.sortable?
          column.apply_order(query, order_direction)
        else
          if column.reflection
            self.virtual_sort_column = ["#{column.options[:through] || column.name}.#{column.option_text_attribute}", order_direction]
          else
            self.virtual_sort_column = [column_name, order_direction]
          end
          query
        end
      else
        self.virtual_sort_column = [column_name, order_direction]
        query
      end
    end

    # Returns the includes to add to the query
    def includes
      @includes ||= self.columns.map{|col| col.includes}.flatten.uniq
    end

    # Returns the joins to add to the query
    def joins
      full_joins = self.columns.map{|col| col.joins}.flatten.uniq
      @joins ||= remove_through_model(full_joins - includes)
    end

    def arraify(objects)
      objects.collect do |object|
        self.columns.collect {|col| col.json(object) }
      end
    end

    def javascript_column_model(screen_in_params)
      @javascript_column_model = self.columns.collect {|column| column.to_column_model(screen_in_params)}.to_json
    end
    
    def toolbar_items
      self.toolbar.items
    end

    def map_attrs(attrs, type, object)
      new_attrs = {}
      attrs.each do |column_name, value|
        if column = self.columns.find{|c| c.full_name == column_name.to_s || c.name.to_s == column_name.to_s }
          column.assign_attribute(object, value, new_attrs, attrs, type)
        end
      end
      attrs.delete_if {|key, value| invalid_attr?(key.to_s) }
      new_attrs
    end

    def invalid_attr?(attr_name)
      attr_name !~ /_attributes$/ and model_columns.exclude?(attr_name) and !model.public_method_defined?("#{attr_name}=")
    end

    private

    # remove some relations which are the through relations, otherwise the query will includes or joins the model twice
    # (one from itself, one from the model which related with main model through it)
    def remove_through_model(relations)
      relations_dup = relations.dup
      relations_dup.each do |relation|
        relations_dup.delete(model.reflections[relation].options[:through])
      end
      relations_dup
    end
    
    def find_sort_column_by_name(column_name)
      if column = find_column_by_name(column_name) and column.options[:sortable] != false
        column
      end
    end
    
    def find_filter_column_by_name(column_name)
      if column = find_column_by_name(column_name) and column.options[:filterable] != false
        column
      end
    end
    
    def find_column_by_name(column_name)
      self.columns.find{|c| c.full_name == column_name.to_s || c.name.to_s == column_name.to_s } || self.columns.find{|c| c.foreign_key == column_name.to_s}
    end

    def initialize_toolbar(current_user=nil)
      self.toolbar ||= Toolbar.new(name, self.toolbar_actions(current_user))
    end
  end
end