require 'wulin_master/components/grid/column/column_filter'
require 'wulin_master/components/grid/column/column_attr'

module WulinMaster
  class Column
    include WulinMaster::ColumnFilter
    include WulinMaster::ColumnAttr

    attr_accessor :name, :options, :datetime_value, :datetime_excel_format

    def initialize(name, grid_class, opts = {})
      @name = name
      @grid_class = grid_class
      @options = {width: 150, sortable: true}.merge(opts)
    end

    def label
      @options[:label] || @name.to_s.underscore.humanize
    end

    def singular_name
      @singular_name ||= reflection ? ActiveModel::Naming.singular(reflection.klass) : source.to_s.singularize
    end

    def datetime_format
      @options[:datetime_format] || WulinMaster.default_datetime_format
    end

    def relation_table_name
      options[:join_aliased_as] || reflection.klass.table_name
    end

    def relation_klass_name
      @relation_klass_name ||= reflection.klass.name
    end

    def table_name
      reflection ? relation_table_name : model.table_name.to_s
    end

    def klass_name
      @class_name ||= reflection ? relation_klass_name : model.name
    end

    def field_name
      reflection ? reflection.name : name
    end

    def to_column_model(screen_name)
      @options[:screen] = screen_name

      # if the option :choices is a Proc, keep it, and call it when using it
      if @options[:original_choices].nil? && @options[:choices].is_a?(Proc)
        @options[:original_choices] = @options[:choices].dup
        @options[:choices] = @options[:choices].call
      elsif @options[:original_choices].is_a?(Proc)
        @options[:choices] = @options[:original_choices].call
      end

      # append choices option to all string columns for applying auto_complete features
      append_choices if sql_type == :string

      sort_col_name = @options[:sort_column] || full_name
      column_type = sql_type
      # Disbale editting, sorting, filtering for colunms calculated by model method
      unless table_column? || related_column_filterable?
        %w[editable sortable filterable].each { |k| @options[k] = false }
      end
      new_options = @options.dup
      h = {
        id: full_name,
        column_name: name,
        singular_name: singular_name,
        name: label,
        table: table_name,
        klass_name: klass_name,
        field: field_name,
        type: column_type,
        sortColumn: sort_col_name
      }.merge(new_options)
      h.merge!(reflection_options) if reflection
      h
    end

    # Format a value
    # Called during json rendering
    def format(value)
      @datetime_value = nil
      @datetime_excel_format = nil

      if (value.class == ActiveSupport::TimeWithZone) || (@options[:type] == 'Datetime')
        @datetime_value = value
        if sql_type == :time || options[:inner_sql_type] == :time
          @datetime_excel_format = 'hh:mm'
          value.try(:strftime, "%H:%M")
        elsif sql_type == :date || options[:inner_sql_type] == :date
          @datetime_excel_format = 'dd/mm/yyyy'
          value.try(:strftime, "%d/%m/%Y")
        else
          @datetime_excel_format = 'dd/mm/yyyy hh:mm'
          value.to_formatted_s(datetime_format)
        end
      elsif value.class == Date
        @datetime_value = value
        @datetime_excel_format = 'dd/mm/yyyy'
        value.try(:strftime, "%d/%m/%Y")
      elsif value.class == Time
        @datetime_value = value
        @datetime_excel_format = 'hh:mm'
        value.strftime('%H:%M')
      elsif value.class == Hash
        value.to_s
      elsif value.class.name == 'BSON::ObjectId'
        value.to_s
      else
        value
      end
    end

    # Dynamically add some new options to the column
    def add_options(new_options = {})
      @options.merge!(new_options)
    end

    def apply_order(query, direction)
      return query unless %w[ASC DESC].include?(direction)
      if @options[:sql_expression]
        query.order("#{@options[:sql_expression]} #{direction}, #{model.table_name}.id ASC")
      elsif reflection
        query.order("#{relation_table_name}.#{source} #{direction}, #{model.table_name}.id ASC")
      elsif table_column?
        order_str = "#{model.table_name}.#{source} #{direction}"
        order_str << ", #{model.table_name}.id ASC" if model < ActiveRecord::Base
        query.order(order_str)
      else
        Rails.logger.warn "Sorting column ignored because this column can't be sorted: #{inspect}"
        query
      end
    end

    def model
      @model ||= @grid_class.model
    end

    def model_columns
      @model_columns ||= begin
        return [] unless model
        model.respond_to?(:all_columns) ? model.all_columns : model.columns
      end
    end

    def sql_type
      return :unknown if model.blank?
      if reflection
        options[:inner_sql_type] = reflection.klass.columns.find { |c| c.name.to_s == source.to_s }.try(:type)
        options[:inner_formatter] ||= (options.delete(:formatter) || options[:inner_sql_type])
        return association_type
      end
      column = model_columns.find { |col| col.name.to_s == source.to_s }
      (enum? ? :enum : (column.try(:type) || association_type || options[:sql_type] || :unknown)).to_s.to_sym
    end

    def reflection
      @reflection ||= model.reflections[(@options[:through] || @name).to_s]
    end

    def append_choices
      @options[:choices] ||= begin
        params_hash = {
          grid: @grid_class.name,
          column: source.to_s,
          source: form_name,
          klass: klass_name,
          screen: @options[:screen]
        }
        "/wulin_master/fetch_distinct_options?#{params_hash.to_param}"
      end
    end

    def reflection_options
      @options[:choices] ||= begin
        if reflection
          params_hash = {
            grid: @grid_class.name,
            column: @name.to_s,
            source: source,
            klass: klass_name,
            screen: @options[:screen]
          }
          "/wulin_master/fetch_options?#{params_hash.to_param}"
        elsif @options[:distinct]
          params_hash = {
            grid: @grid_class.name,
            column: @name.to_s,
            source: form_name,
            klass: klass_name,
            screen: @options[:screen]
          }
          "/wulin_master/fetch_distinct_options?#{params_hash.to_param}"
        else
          []
        end
      end
      { choices: @options[:choices], source: source }
    end

    # Spec: Suppose a post belongs_to an author
    # - column :author_email, source: :email, through: :author  -> source = :email (of author)
    # - column :email, through: :author                         -> source = :email (of author)
    # - column :author                                          -> source = :name  (of author)
    # - column :title                                           -> source = :title (of post)
    def source
      @options[:source].presence || (@options[:through] ? name : (reflection ? :name : name))
    end

    def full_name
      if @options[:through]
        if @options[:source]
          "#{@options[:through]}_#{@options[:source]}"
        else
          "#{@options[:through]}_#{name}"
        end
      elsif @options[:source]
        "#{name}_#{@options[:source]}"
      elsif !model.column_names.include?(name.to_s) && model.reflections[name.to_s]
        "#{name}_name"
      else
        name.to_s
      end
    end

    def foreign_key
      @foreign_key ||= reflection.try(:foreign_key).to_s
    end

    def form_name
      @form_name ||= foreign_key.presence || source
    end

    # Returns the sql names used to generate the select
    def sql_names
      if table_column?
        if reflection
          [model.table_name + "." + foreign_key, reflection.klass.table_name + "." + source.to_s]
        else
          [model.table_name + "." + source.to_s]
        end
      end
    end

    def presence_required?
      !!model.validators.find do |validator|
        (validator.class == ActiveModel::Validations::PresenceValidator) && validator.attributes.include?(form_name.to_sym)
      end
    end

    # Returns the includes to add to the query
    def includes
      if reflection && (reflection.class < ActiveRecord::Reflection::AbstractReflection)
        [(@options[:through] || @name).to_sym, association_through ? association_through.to_sym : nil].compact
      else
        []
      end
    end

    # Returns the joins to add to the query
    def joins
      if reflection && (reflection.class < ActiveRecord::Reflection::AbstractReflection) && presence_required?
        [(@options[:through] || @name).to_sym]
      else
        []
      end
    end

    # Returns the value for the object in argument
    def value(object)
      case association_type.to_s
      when /^belongs_to$|^has_one$/
        object.send(@options[:through] || name).try(:send, source).to_s
      when 'has_and_belongs_to_many'
        ids = object.send("#{reflection.klass.name.underscore}_ids")
        object.send(reflection.name.to_s).map { |x| x.send(source) }.join(',')
      when 'has_many'
        object.send(source.to_s).collect { |obj| obj.send(source) }
      else
        format(object.send(source.to_s))
      end
    end

    def editor_source
      @options[:editor][:source] if @options[:editor].is_a?(Hash)
    end

    # Returns the json for the object in argument
    def json(object)
      case association_type.to_s
      when 'belongs_to', 'has_one'
        association_object = object.send(@options[:through] || name)
        reflection_info = {}
        reflection_info[:id] = association_object.try(:id)
        reflection_info[source] = format(association_object.try(:send, source))
        reflection_info[editor_source] = format(association_object.try(:send, editor_source)) if editor_source
        { reflection.name => reflection_info }
      when 'has_and_belongs_to_many'
        {reflection.name => format_multiple_objects(object.send(reflection.name.to_s))}
      when 'has_many'
        {reflection.name => format_multiple_objects(object.send(@options[:through] || name))}
      else
        format(object.send(source.to_s))
      end
    end

    def valid_in_screen(screen_name)
      screen_name = screen_name.to_s
      (@options[:only].blank? && @options[:except].blank?) ||
        (@options[:only].present? && @options[:only].map(&:to_s).include?(screen_name)) ||
        (@options[:except].present? && @options[:except].map(&:to_s).exclude?(screen_name))
    end

    def sortable?
      @options[:sortable] || table_column? || nosql_field? || related_column_filterable? || @options[:sql_expression]
    end

    def enum?
      enums = model.try(:defined_enums)
      enums&.key?(source.to_s)
    end

    alias filterable? sortable?

    private

    def related_column_filterable?
      reflection&.klass&.column_names&.include?(source.to_s)
    end

    def complete_column_name
      if @options[:sql_expression]
        (@options[:sql_expression]).to_s
      elsif table_column?
        "#{model.table_name}.#{source}"
      elsif reflection
        "#{reflection.klass.table_name}.#{source}"
      else
        source
      end
    end

    def column_type(model, column_name)
      all_columns = model.respond_to?(:all_columns) ? model.all_columns : model.columns
      column = all_columns.find { |col| col.name.to_s == column_name.to_s }
      (column.try(:type) || :unknown).to_s.to_sym
    end

    def table_column?
      model.respond_to?(:column_names) ? model.column_names.include?(name.to_s) : false
    end

    def nosql_field?
      model.ancestors.exclude?(ActiveModel::Serializers::JSON)
    end

    def association_type
      reflection.try(:macro)
    end

    def association_through
      reflection ? reflection.try(:options)[:through] : nil
    end

    def format_multiple_objects(objects)
      value = {:id => [], source => []}
      objects.each do |obj|
        value[:id] << obj.id
        value[source] << format(obj.send(source))
      end
      value[source] = value[source].join(', ')
      value
    end
  end
end
