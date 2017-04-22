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

    cattr_accessor(:grids) { [] }

    class_attribute :_model, :_path, :titles_pool

    DEFAULT_CONFIG = {fill_window: true}

    # Grid has been subclassed
    def self.inherited(klass)
      self.grids << klass
      klass.init
    end

    class << self
      attr_accessor :controller_class

      # Called when the grid is subclassed
      def init
        initialize_columns
        load_default_behaviors  # load default behaviors here rather than in application code

        cell_editable
        column_sortable

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
        screen_name = options[:screen]
        if new_title
          screen_name ? self.titles_pool[screen_name] = new_title : self.titles_pool[:_common] = new_title
        else
          self.titles_pool[screen_name] || self.titles_pool[:_common] || self.to_s.gsub(/Grid/, "")
        end
      end
    end

    attr_accessor :toolbar, :current_user, :virtual_sort_column, :virtual_filter_columns

    def initialize(screen_instance=nil, config={})
      super
      @current_user = @screen.current_user
      initialize_toolbar if params[:format] != 'json'
    end

    def is_grid?
      true
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

    def name
      WulinMaster::Utilities.get_grid_name(self.class.name, self.screen.class.name)
    end

    def model_columns
      @model_columns ||= model.column_names
    end

    def path
      uri = URI.parse(self.class.path)
      uri.query = [uri.query, "grid=#{self.class.to_s}"].compact.join('&')
      uri.to_s
    end

    def path_for_json
      query_parameters = controller.request.query_parameters
      uri = URI.parse(self.path).dup
      uri.path << ".json"
      uri.query = [uri.query, query_parameters.to_query].compact.join('&')
      uri.to_s
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
            self.virtual_filter_columns << ["#{column.options[:through] || column.name}.#{column.source}", filtering_value, filtering_operator]
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
            self.virtual_sort_column = ["#{column.options[:through] || column.name}.#{column.source}", order_direction]
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

    def full_includes
      @full_includes ||= self.columns.map{|col| col.includes}.flatten.uniq
    end

    # Returns the includes to add to the query
    def includes
      @includes ||= remove_through_model(full_includes)
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

    def javascript_column_model
      @javascript_column_model = self.columns.collect {|column| column.to_column_model(params[:screen])}.to_json
    end

    def toolbar_items
      self.toolbar.items
    end

    def map_attrs(attrs, type, object)
      new_attrs = {}
      attrs.each do |column_name, value|
        if column = self.columns.find{|c| c.full_name == column_name.to_s || c.name.to_s == column_name.to_s || c.options[:through].to_s == column_name.to_s}
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
        relations_dup.delete(model.reflections[relation.to_s].options[:through])
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

    def initialize_toolbar
      self.toolbar ||= Toolbar.new(name, self.toolbar_actions)
    end
  end
end
