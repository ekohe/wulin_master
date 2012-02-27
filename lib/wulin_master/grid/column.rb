module WulinMaster
  class Column
    attr_accessor :name, :options

    def initialize(name, grid_class, opts={})
      @name = name
      @grid_class = grid_class
      @options = {:width => 150, :sortable => true, :editable => true}.merge(opts)
    end

    def label
      @options[:label] || @name.to_s.underscore.humanize
    end

    def datetime_format
      @options[:datetime_format] || WulinMaster.default_datetime_format
    end

    def to_column_model
      field_name = @name.to_s
      sort_col_name = self.reflection ? self.option_text_attribute : @name.to_s
      table_name = self.reflection ? self.reflection.klass.table_name.to_s : self.model.table_name.to_s
      new_options = @options.dup
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

      if self.model.column_names.include?(self.name.to_s)
        complete_column_name = "#{model.table_name}.#{self.name}"
      else
        complete_column_name = self.name
      end

      if self.reflection
        table_name = options[:join_aliased_as] || self.reflection.klass.table_name
        return query.where(["UPPER(#{table_name}.#{self.option_text_attribute}) LIKE UPPER(?)", filtering_value+"%"])
      else
        case sql_type.to_s
        when 'date'
          return query.where(["to_char(#{self.name}, 'YYYY-MM-DD') LIKE UPPER(?)", filtering_value+"%"])
        when "datetime"
          return query.where(["to_char(#{self.name}, 'YYYY-MM-DD') LIKE UPPER(?)", filtering_value+"%"])
        when "boolean"
          true_values = ["y", "yes", "ye", "t", "true"]
          true_or_false = true_values.include?(filtering_value.downcase)
          if model < ActiveRecord::Base
            return query.where(complete_column_name => true_or_false)
          else
            if true_or_false
              return query.where(self.name => true)
            else
              return query.any_in(self.name => [nil, false])
            end
          end
        else
          filtering_value = filtering_value.gsub(/'/, "''")
          if sql_type.to_s == 'integer' and self.name.to_s =~ /_id$/ and self.model.column_names.include?(self.name.to_s)
            return query.where(self.name => filtering_value)
          elsif model < ActiveRecord::Base
            return query.where(["UPPER(#{complete_column_name}) LIKE UPPER(?)", filtering_value+"%"])
          else
            if options[:type] == 'Datetime' and format_datetime(filtering_value).present? # Datetime filter for Mongodb
              return query.where(
              self.name.to_sym.gte => format_datetime(filtering_value)[:from], 
              self.name.to_sym.lte => format_datetime(filtering_value)[:to]
              )
            else
              return query.where(self.name => Regexp.new("#{Regexp.escape(filtering_value)}.*", true))
            end
          end
        end
      end
      query
    end

    def apply_order(query, direction)
      return query unless ["ASC", "DESC"].include?(direction)
      if self.reflection
        table_name = options[:join_aliased_as] || self.reflection.klass.table_name
        query.order("#{table_name}.#{self.option_text_attribute} #{direction}")
      else
        query.order("#{model.table_name}.#{@name} #{direction}")
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
      @reflection ||= self.model.reflections[(@options[:through] || @name).to_sym]
    end

    def choices
      @choices ||= if self.reflection
        reflection_class = self.reflection.klass
        params_hash = { :controller_name => "#{reflection_class.name.pluralize}Controller", :klass => reflection_class.name, :text_attr => option_text_attribute }
        "/wulin_master/fetch_options?#{params_hash.to_param}"
      else
        []
      end
    end

    def reflection_options
      if @options[:choices].present?
        choices = @options[:choices].to_json
      else
        choices = self.choices
      end
      
      { :choices => choices, :optionTextAttribute => self.option_text_attribute }
    end
    
    # For belongs_to association, the name of the attribute to display
    def option_text_attribute
      if @options[:through]
        return self.name
      else
        return @options[:option_text_attribute] || :name
      end
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
        [(@options[:through] || @name).to_sym]
      else
        []
      end
    end

    # Returns the´joins to add to the query
    def joins
      if self.reflection && presence_required?
        [(@options[:through] || @name).to_sym]
      else
        []
      end
    end

    # Returns the json for the object in argument
    def json(object) 
      if association_type.to_s == 'belongs_to'
        {:id => object.send(self.reflection.foreign_key.to_s),
          option_text_attribute => object.send(@options[:through] || self.name).try(:send,option_text_attribute).to_s}
      elsif association_type.to_s == 'has_one'
        association_object = object.send(@options[:through] || self.name)
        {:id => association_object.try(:id), option_text_attribute => association_object.try(:send,option_text_attribute).to_s}
      elsif association_type.to_s == 'has_and_belongs_to_many'
        ids = object.send("#{self.reflection.klass.name.underscore}_ids")
        op_attribute = object.send(self.reflection.name.to_s).map{|x| x.send(option_text_attribute)}.join(',')
        {id: ids, option_text_attribute => op_attribute}
      elsif association_type.to_s == 'has_many'
        object.send(self.name.to_s).collect{|obj| {:id => obj.id, option_text_attribute => obj.send(option_text_attribute)}}
      else
        self.format(object.send(self.name.to_s))
      end
    end


    # == Generate the datetime rang filter for mongodb
    def format_datetime(datetime)
      if datetime =~ /^\d{1,4}-?$/ # 20 2011 2011-
        year = datetime.first(4)
        from_year = year.size <=3 ? (year + '0' * (4 - 1 - year.size) + '1') : year
        to_year = year + '9' * (4 - year.size)
        { from: build_datetime(from_year.to_i), to: build_datetime(to_year.to_i, 12, 31, 23, 59, 59) } # 2011-01-01 - 2011-12-31  2001-01-01 - 2099-12-31
      elsif datetime =~ /^\d{1,4}-[0-1]$/ # 2011-0 - 2011-1
        year, month = datetime.split('-').map(&:to_i)
        if month == 0
          { from: build_datetime(year), to: build_datetime(year, 9, 30, 23, 59, 59) } # 2011-01-01 - 2011-09-31
        elsif month == 1
          { from: build_datetime(year, 10), to: build_datetime(year, 12, 31, 23, 59, 59) } # 2011-10-01 - 2011-12-31
        end
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-1])-?$/ # 2011-01 - 2011-09  or  2011-10 - 2011-11
        year, month = datetime.first(7).split('-').map(&:to_i)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month), to: build_datetime(year, month, 31, 23, 59, 59) } # 2011-01-01 - 2011-01-31
        else
          { from: build_datetime(year, month), to: build_datetime(year, month, 30, 23, 59, 59) } # 2011-02-01 - 2011-02-30
        end
      elsif datetime =~ /^\d{1,4}-12-?$/ # 2011-12
        year = datetime.first(4).to_i
        { from: build_datetime(year, 12), to: build_datetime(year, 12, 31, 23, 59, 59) } # 2011-12-01 - 2011-12-31
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-0$/ # 2011-12-0
        year, month, date = datetime.split('-').map(&:to_i)
        { from: build_datetime(year, month, 1), to: build_datetime(year, month, 9, 23, 59, 59)} # 2011-12-01 - 2011-12-09
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-[1-2]$/ # 2011-12-1 2011-12-2
        year, month, date = datetime.split('-').map(&:to_i)
        { from: build_datetime(year, month, date * 10), to: build_datetime(year, month, (date * 10) + 9, 23, 59, 59) } # 2011-12-01 - 2011-12-09
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-[3]$/ # 2011-12-3
        year, month, date = datetime.split('-').map(&:to_i)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 31, 23, 59, 59) } # 2011-12-30 - 2011-12-31
        else
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 30, 23, 59, 59) } # 2011-12-30 - 2011-12-30
        end
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-3[0-1]\s?$/ # 2011-12-31  2011-11-30
        year, month, date = datetime.split('-').map(&:to_i)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month, date), to: build_datetime(year, month, date, 23, 59, 59) } # 2011-12-30 - 2011-12-31
        elsif date == 30
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 30, 23, 59, 59) } # 2011-12-30 - 2011-12-30
        end
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s?$/ # 2011-12-01 - 2011-12-29
        year, month, date = datetime.split('-').map(&:to_i)
        { from: build_datetime(year, month, date), to: build_datetime(year, month, date, 23, 59, 59) } # 2011-11-11 00:00:00 - 2011-11-11 23:59:59
        # Time part
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s[0-1]$/ # 2011-11-11 0   2011-11-11 1
        year, month, date = datetime.split(/\s/)[0].split('-').map(&:to_i)
        hour =  datetime.split(/\s/)[1]
        { from: build_datetime(year, month, date, (hour + '0').to_i), to: build_datetime(year, month, date, (hour + '9').to_i, 59, 59) } # 2011-11-11 00:00:00 - 2011-11-11 09:59:59
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s2$/ # 2011-11-11 2
        year, month, date = datetime.split(/\s/)[0].split('-').map(&:to_i)
        { from: build_datetime(year, month, date, 20), to: build_datetime(year, month, date, 23, 59, 59) } # 2011-11-11 20:00:00 - 2011-11-11 23:59:59
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):?$/ # 2011-11-11 23   2011-11-11 23:
        year, month, date = datetime.split(/\s/)[0].split('-').map(&:to_i)
        hour = datetime.split(/\s/)[1].first(2).to_i
        { from: build_datetime(year, month, date, hour), to: build_datetime(year, month, date, hour, 59, 59) } # 2011-11-11 20:00:00 - 2011-11-11 20:59:59
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):[0-5]$/ # 2011-11-11 23:0   2011-11-11 23:5
        year, month, date = datetime.split(/\s/)[0].split('-').map(&:to_i)
        hour, minute = datetime.split(/\s/)[1].split(':')
        { from: build_datetime(year, month, date, hour.to_i, (minute + '0').to_i), to: build_datetime(year, month, date, hour.to_i, (minute + '9').to_i, 59) } # 2011-11-11 20:00:00 - 2011-11-11 20:59:59
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):[0-5][0-9]:?$/ # 2011-11-11 23:00   2011-11-11 23:59
        year, month, date = datetime.split(/\s/)[0].split('-').map(&:to_i)
        hour, minute = datetime.split(/\s/)[1].split(':').map(&:to_i)
        { from: build_datetime(year, month, date, hour, minute), to: build_datetime(year, month, date, hour, minute, 59) } # 2011-11-11 20:00:00 - 2011-11-11 20:59:59
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5]$/ # 2011-11-11 23:24:0    2011-11-11 23:24:5
        year, month, date = datetime.split(/\s/)[0].split('-').map(&:to_i)
        hour, minute, second = datetime.split(/\s/)[1].split(':').map(&:to_i)
        { from: build_datetime(year, month, date, hour, minute, (second.to_s + '0').to_i), to: build_datetime(year, month, date, hour, minute, (second.to_s + '9').to_i) } # 2011-11-11 20:00:00 - 2011-11-11 20:00:59
      elsif datetime =~ /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9].*$/ # 2011-11-11 23:24:04    2011-11-11 23:24:54
        datetime = datetime.first(19)
        year, month, date = datetime.split(/\s/)[0].split('-').map(&:to_i)
        hour, minute, second = datetime.split(/\s/)[1].split(':').map(&:to_i)
        { from: build_datetime(year, month, date, hour, minute, second), to: build_datetime(year, month, date, hour, minute, second) } # 2011-11-11 20:22:22 - 2011-11-11 20:22:22
      else
        {}
      end
    end

    def build_datetime(*args)
      DateTime.new(*args) rescue nil
    end

    private

    def association_type
      self.reflection.try(:macro)
    end
  end
end
