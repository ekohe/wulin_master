module WulinMaster
  class Column
    attr_accessor :name, :options

    def initialize(name, grid, opts={})
      @name = name
      @grid = grid
      @options = {:width => 80, :sortable => true, :editable => true}.merge(opts)
    end

    def label
      @options[:label] || @name.to_s.underscore.humanize
    end

    def datetime_format
      @options[:datetime_format] || WulinMaster.default_datetime_format
    end

    def to_column_model
      {:id => @name, :name => self.label, :field => @name, :type => sql_type}.merge(options)
    end

    # Format a value 
    # Called during json rendering
    def format(value)
      if value.class == Time || value.class == ActiveSupport::TimeWithZone
        value.to_formatted_s(datetime_format)
      else
        value
      end
    end

    # Apply a where condition on the query to filter the result set with the filtering value
    def apply_filter(query, filtering_value)
      return query if filtering_value.blank?

      case sql_type
      when :datetime
        # For a list of datetime conversion types:
        # http://msdn.microsoft.com/en-us/library/ms187928.aspx
        # 20 is the ODBC canonical type: yyyy-mm-dd hh:mi:ss(24h)
        return query.where("to_char(#{self.name}, 'YYYY-MM-DD') LIKE UPPER('#{filtering_value}%')")
      else
        filtering_value = filtering_value.gsub(/'/, "''")
        return query.where("UPPER(#{self.name}) LIKE UPPER('#{filtering_value}%')")
      end
    end

    def sql_type
      return :unknown if @grid.nil? or @grid.model.nil?
      column = @grid.model.columns.find {|col| col.name.to_s == self.name.to_s}
      column.type.try(:column) || :unknown
    end
  end
end