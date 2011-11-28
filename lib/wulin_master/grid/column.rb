module WulinMaster
  class Column
    attr_accessor :name, :options

    def initialize(name, grid_class, opts={})
      @name = name
      @grid_class = grid_class
      @options = {:width => 80, :sortable => true, :editable => true}.merge(opts)
    end

    def label
      @options[:label] || @name.to_s.underscore.humanize
    end

    def datetime_format
      @options[:datetime_format] || WulinMaster.default_datetime_format
    end

    def to_column_model
      field_name = self.reflection ? self.reflection.foreign_key.to_s : @name.to_s
      sort_col_name = self.reflection ? self.option_text_attribute : @name.to_s
      table_name = self.reflection ? self.reflection.klass.table_name.to_s : self.model.table_name.to_s
      new_options = @options.dup
      @options.each {|k,v| new_options.merge!(k => v.call) if v.class == Proc }
      h = {:id => @name, :name => self.label, :table => table_name, :field => field_name, :type => sql_type, :sortColumn => sort_col_name}.merge(new_options)
      h.merge!(reflection_options) if reflection
      h
    end

    # Format a value 
    # Called during json rendering
    def format(value)
      if value.class == Time || value.class == ActiveSupport::TimeWithZone
        value.to_formatted_s(datetime_format)
      elsif value.class.name == 'BSON::ObjectId'
        value.to_s
      else
        value
      end
    end

    # Apply a where condition on the query to filter the result set with the filtering value
    def apply_filter(query, filtering_value)
      return query if filtering_value.blank?
      if self.reflection
        return query.where("UPPER(#{self.reflection.plural_name}.#{self.option_text_attribute}) LIKE UPPER('#{filtering_value}%')")
      else
        case sql_type.to_s
        when "datetime"
          return query.where("to_char(#{self.name}, 'YYYY-MM-DD') LIKE UPPER('#{filtering_value}%')")
        else
          filtering_value = filtering_value.gsub(/'/, "''")
          return query.where("UPPER(#{model.table_name}.#{self.name}) LIKE UPPER('#{filtering_value}%')")
        end
      end
    end

    def model
      @grid_class.model
    end

    # Function name isn't good
    def sql_type
      return :unknown if self.model.blank?
      column = (self.model.respond_to?(:all_columns) ? self.model.all_columns : self.model.columns).find {|col| col.name.to_s == self.name.to_s}
      (column.try(:type) || association_type || :unknown).to_s.to_sym
    end

    def reflection
      @reflection ||= self.model.reflections[@name.to_sym]
    end

    def choices
      @choices ||= (self.reflection ? self.reflection.klass.all : [])
    end

    def reflection_options
      {:choices => (@options[:choices].present? ? @options[:choices].to_json : nil) || self.choices.collect{|k| {:id => k.id, option_text_attribute => k.send(option_text_attribute)}},
      :optionTextAttribute => self.option_text_attribute}
    end

    def foreign_key
      self.reflection.try(:foreign_key)
    end

    def form_name
      self.reflection ? self.foreign_key : self.name
    end

    # Returns the sql names used to generate the select
    def sql_names
      if self.reflection.nil?
        [self.model.table_name+"."+name.to_s]
      else
        [self.model.table_name+"."+self.reflection.foreign_key.to_s, self.reflection.klass.table_name+"."+option_text_attribute.to_s]
      end
    end

    def presence_required?
      self.model.validators.find{|validator| validator.class == ActiveModel::Validations::PresenceValidator &&validator.attributes.include?(@name.to_sym)}
    end

    # Returns the´includes to add to the query 
    def includes
      if self.reflection
        [@name.to_sym]
      else
        []
      end
    end

    # Returns the´joins to add to the query
    def joins
      if self.reflection && presence_required?
        [@name.to_sym]
      else
        []
      end
    end

    # Returns the json for the object in argument
    def json(object)
      if association_type.to_s == 'belongs_to'
        {:id => object.send(self.reflection.foreign_key.to_s), option_text_attribute => object.send(self.name.to_sym).try(:send,option_text_attribute).to_s}
      elsif association_type.to_s == 'has_and_belongs_to_many'
        ids = object.send("#{self.reflection.klass.name.underscore}_ids")
        op_attribute = object.send(self.reflection.name.to_s).map{|x| x.send(option_text_attribute)}.join(',')
        {id: ids, option_text_attribute => op_attribute}
      else
        self.format(object.send(self.name.to_s))
      end
    end

    # For belongs_to association, the name of the attribute to display
    def option_text_attribute
      @options[:option_text_attribute] || :name
    end

    private

    def association_type
      self.reflection.try(:macro)
    end
  end
end
