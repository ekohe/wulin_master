require 'wulin_master/components/grid/column/column_filter'
require 'wulin_master/components/grid/column/column_attr'

module WulinMaster
  class Column
    include WulinMaster::ColumnFilter
    include WulinMaster::ColumnAttr

    attr_accessor :name, :options, :datetime_value, :datetime_excel_format

    def initialize(name, grid_class, opts={})
      @name = name
      @grid_class = grid_class
      @options = {:width => WulinMaster.config.default_column_width, :sortable => true}.merge(opts)
    end

    def label
      # @options[:label] || @name.to_s.underscore.humanize
      @options[:label] || model.human_attribute_name(@name)
    end

    def singular_name
       @singular_name ||= self.reflection ? ActiveModel::Naming.singular(self.reflection.klass) : name.to_s.singularize
    end

    def datetime_format
      @options[:datetime_format] || WulinMaster.default_datetime_format
    end

    def relation_table_name
      options[:join_aliased_as] || self.reflection.klass.table_name
    end

    def relation_klass_name
      @relation_klass_name ||= self.reflection.klass.name
    end

    def table_name
      self.reflection ? relation_table_name : self.model.table_name.to_s
    end

    def klass_name
      @class_name ||= self.reflection ? relation_klass_name : self.model.name
    end

    def field_name
      self.reflection ? reflection.name : name
    end

    def to_column_model(screen_name)
      @options[:screen] = screen_name

      # if the option :choices is a Proc, keep it, and call it when using it
      if @options[:original_choices].nil? and @options[:choices].is_a?(Proc)
        @options[:original_choices] = @options[:choices].dup
        @options[:choices] = @options[:choices].call
      elsif @options[:original_choices].is_a?(Proc)
        @options[:choices] = @options[:original_choices].call
      end

      @options[:required] = presence_required?

      append_distinct_options if @options[:distinct] || @options[:auto_complete]
      sort_col_name = @options[:sort_column] || full_name
      column_type = sql_type
      new_options = @options.dup
      h = {:id => full_name, :column_name => self.name, :singular_name => self.singular_name, :name => self.label, :table => table_name, :klass_name => klass_name, :field => field_name, :type => column_type, :sortColumn => sort_col_name}.merge(new_options)
      h.merge!(reflection_options) if reflection
      h
    end

    # Format a value
    # Called during json rendering
    def format(value)
      @datetime_value = nil
      @datetime_excel_format = nil

      if @options[:simple_date]
        @datetime_value = value
        @datetime_excel_format = 'dd mmm'
        value.respond_to?(:strftime) ? value.strftime('%d %b') : value
      elsif @options[:simple_time]
        @datetime_value = value
        @datetime_excel_format = 'hh:mm'
        value.respond_to?(:strftime) ? value.strftime('%H:%M') : value
      else
        if value.class == ActiveSupport::TimeWithZone or @options[:type] == 'Datetime'
          @datetime_value = value
          if self.sql_type == :time
            @datetime_excel_format = 'hh:mm'
            value.try(:strftime, "%H:%M")
          elsif self.sql_type == :date
            @datetime_excel_format = 'yyyy-mm-dd'
            value.try(:strftime, "%Y-%m-%d")
          else
            @datetime_excel_format = 'yyyy-mm-dd hh:mm'
            value.to_formatted_s(datetime_format)
          end
        elsif value.class == Time
          @datetime_value = value
          @datetime_excel_format = 'hh:mm'
          value.strftime('%H:%M')
        elsif value.class.name == 'BSON::ObjectId'
          value.to_s
        else
          value
        end
      end
    end

    # Dynamically add some new options to the column
    def add_options(new_options={})
      @options.merge!(new_options)
    end

    def apply_order(query, direction)
      return query unless ["ASC", "DESC"].include?(direction)
      if @options[:sql_expression]
        query.order("#{@options[:sql_expression]} #{direction}, #{model.table_name}.id ASC")
      elsif self.reflection
        query.order("#{relation_table_name}.#{self.option_text_attribute} #{direction}, #{model.table_name}.id ASC")
      elsif is_table_column?
        order_str = "#{model.table_name}.#{@name} #{direction}"
        order_str << ", #{model.table_name}.id ASC" if model < ActiveRecord::Base
        query.order(order_str)
      else
        Rails.logger.warn "Sorting column ignored because this column can't be sorted: #{self.inspect}"
        query
      end
    end

    def model
      @model ||= @grid_class.model
    end

    def model_columns
      @model_columns ||= begin
        return [] unless model
        self.model.respond_to?(:all_columns) ? self.model.all_columns : self.model.columns
      end
    end

    def sql_type
      return :unknown if self.model.blank?
      if reflection
        options[:inner_sql_type] = reflection.klass.columns.find{|c| c.name.to_s == self.name.to_s}.try(:type)
        options[:inner_formatter] ||= (options.delete(:formatter) || options[:inner_sql_type])
        return association_type
      end
      column = model_columns.find {|col| col.name.to_s == self.name.to_s}
      (column.try(:type) || association_type || self.options[:sql_type] || :unknown ).to_s.to_sym
    end

    def reflection
      @reflection ||= self.model.reflections[(@options[:through] || @name).to_sym]
    end

    def append_distinct_options
      @options[:choices] ||= begin
        params_hash = { :grid => @grid_class.name, :column => @name.to_s, :text_attr => form_name, klass: klass_name, :screen => @options[:screen] }
        "/wulin_master/fetch_distinct_options?#{params_hash.to_param}"
      end
    end

    def reflection_options
      @options[:choices] ||= begin
        if self.reflection
          params_hash = { :grid => @grid_class.name, :column => @name.to_s, :text_attr => option_text_attribute, :screen => @options[:screen] }
          "/wulin_master/fetch_options?#{params_hash.to_param}"
        elsif @options[:distinct]
          params_hash = { :grid => @grid_class.name, :column => @name.to_s, :text_attr => form_name, klass: klass_name, :screen => @options[:screen] }
          "/wulin_master/fetch_distinct_options?#{params_hash.to_param}"
        else
          []
        end
      end
      { :choices => @options[:choices], :optionTextAttribute => self.option_text_attribute }
    end

    # For belongs_to association, the name of the attribute to display
    def option_text_attribute
      @options[:option_text_attribute].presence || (@options[:through] ? self.name : :name)
    end

    def full_name
      if @options[:option_text_attribute]
       "#{name}_#{@options[:option_text_attribute].to_s}"
      elsif @options[:through]
        "#{@options[:through]}_#{name}"
      elsif !model.column_names.include?(name.to_s) && model.reflections[name.to_sym]
        "#{name}_name"
      else
        name.to_s
      end
    end

    def foreign_key
      @foreign_key ||= self.reflection.try(:foreign_key).to_s
    end

    def form_name
      @form_name ||= foreign_key.presence || self.name
    end

    # Returns the sql names used to generate the select
    def sql_names
      if is_table_column?
        if self.reflection
          [self.model.table_name + "."+ foreign_key, self.reflection.klass.table_name + "." + option_text_attribute.to_s]
        else
          [self.model.table_name + "." + name.to_s]
        end
      else
        nil
      end
    end

    def presence_required?(model=nil)
      current_model = model || self.model
      if current_model.respond_to?(:validators)
        direct_validator_fields = current_model.validators.select{|x| x.class == ActiveModel::Validations::PresenceValidator}.map(&:attributes).flatten
      else
        direct_validator_fields = []
      end

      if current_model.column_names.include?(form_name.to_s) || current_model.method_defined?(form_name)
        return (direct_validator_fields.include?(form_name.to_sym) || !!direct_validator_fields.find{|f| reflection = current_model.reflections[f.to_sym]; reflection && reflection.foreign_key == form_name.to_s})
      else
        !!direct_validator_fields.find{|f| nested_model = f.to_s.classify.safe_constantize; nested_model && presence_required?(nested_model)}
      end
    end

    # Returns the includes to add to the query
    def includes
      if self.reflection && (self.reflection.klass < ActiveRecord::Base)
        [(@options[:through] || @name).to_sym, association_through ? association_through.to_sym : nil].compact
      else
        []
      end
    end

    # Returns the joins to add to the query
    def joins
      if self.reflection && (self.reflection.klass < ActiveRecord::Base) && presence_required?
        [(@options[:through] || @name).to_sym]
      else
        []
      end
    end

    # Returns the value for the object in argument
    def value(object)
      case association_type.to_s
      when /^belongs_to$|^has_one$/
        object.send(@options[:through] || self.name).try(:send,option_text_attribute).to_s
      when 'has_and_belongs_to_many'
        ids = object.send("#{self.reflection.klass.name.underscore}_ids")
        object.send(self.reflection.name.to_s).map{|x| x.send(option_text_attribute)}.join(',')
      when 'has_many'
        object.send(self.name.to_s).collect{|obj| obj.send(option_text_attribute)}
      else
        self.format(object.send(self.name.to_s))
      end
    end

    # Returns the json for the object in argument
    def json(object)
      case association_type.to_s
      when 'belongs_to'
        value = "#{self.name}_#{option_text_attribute}" == foreign_key.to_s ? object.send(foreign_key) : object.send(@options[:through] || self.name).try(:send, option_text_attribute)
        {reflection.name => {:id => object.send(foreign_key), option_text_attribute => format(value)}}
      when 'has_one'
        association_object = object.send(@options[:through] || self.name)
        {reflection.name => {:id => association_object.try(:id), option_text_attribute => format(association_object.try(:send,option_text_attribute))}}
      when 'has_and_belongs_to_many'
        {reflection.name => format_multiple_objects(object.send(self.reflection.name.to_s))}
      when 'has_many'
        {reflection.name => format_multiple_objects(object.send(self.name.to_s))}
      else
        self.format(object.send(self.name.to_s))
      end
    end

    def valid_in_screen(screen_name)
      screen_name = screen_name.to_s
      (@options[:only].blank? and @options[:except].blank?) ||
      (@options[:only].present? and @options[:only].map(&:to_s).include?(screen_name)) ||
      (@options[:except].present? and @options[:except].map(&:to_s).exclude?(screen_name))
    end

    def sortable?
      @options[:sortable] || is_table_column? || is_nosql_field? || related_column_filterable? || @options[:sql_expression]
    end

    alias_method :filterable?, :sortable?

    private

    def related_column_filterable?
      reflection and reflection.klass.column_names.include?(option_text_attribute.to_s)
    end

    def complete_column_name
      if @options[:sql_expression]
        "#{@options[:sql_expression]}"
      elsif is_table_column?
        "#{model.table_name}.#{self.name}"
      elsif self.reflection
        "#{self.reflection.klass.table_name}.#{self.name}"
      else
        self.name
      end
    end

    def column_type(model, column_name)
      all_columns = model.respond_to?(:all_columns) ? model.all_columns : model.columns
      column = all_columns.find {|col| col.name.to_s == column_name.to_s}
      (column.try(:type) || :unknown).to_s.to_sym
    end

    def is_table_column?
      self.model.respond_to?(:column_names) ? self.model.column_names.include?(self.name.to_s) : false
    end

    def is_nosql_field?
      self.model.ancestors.exclude?(ActiveModel::Serializers::JSON)
    end

    def association_type
      self.reflection.try(:macro)
    end

    def association_through
      self.reflection ? self.reflection.try(:options)[:through] : nil
    end

    def format_multiple_objects(objects)
      value = {:id => [], option_text_attribute => []}
      objects.each do |obj|
        value[:id] << obj.id
        value[option_text_attribute] << format(obj.send(option_text_attribute))
      end
      value[option_text_attribute] = value[option_text_attribute].join(',')
      value
    end
  end
end
