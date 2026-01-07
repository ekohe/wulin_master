# frozen_string_literal: true

require 'wulin_master/components/grid/column/sql_adapter'

module WulinMaster
  module ColumnFilter
    # Apply a where condition on the query to filter the result set with the filtering value
    def apply_filter(query, filtering_value, filtering_operator = 'equals')
      adapter = WulinMaster::SqlAdapter.new(model, query)
      filtering_operator ||= 'equals'
      return query if filtering_value.blank?

      # Search by NULL
      return filter_by_null(query, filtering_value, filtering_operator, adapter) if filtering_value.to_s.casecmp('null').zero?

      # Although RoleUser `belongs_to` user, User (in WulinOAuth) doesn't provide
      # `has_many` relationship to RoleUser since it is not inherited from
      # ActiveRecord. For this reason, query for RoleUser should use filter_without_reflection.
      unless reflection && (defined?(RolesUser) ? query != RolesUser : true)
        return filter_without_reflection(query, filtering_value, filtering_operator, sql_type, adapter)
      end
      filter_with_reflection(query, filtering_value, filtering_operator, adapter)
    end

    private

    def filter_by_null(query, _filtering_value, filtering_operator, adapter)
      operator = case filtering_operator
      when 'equals' then ''
      when 'not_equals' then 'NOT'
      end

      adapter.null_query(complete_column_name, operator, self)
      return adapter.query unless reflection

      if @options[:sql_expression]
        query.where("#{@options[:sql_expression]} IS #{operator} NULL")
      else
        query.where("#{relation_table_name}.#{source} IS #{operator} NULL")
      end
    end

    def filter_with_reflection(query, filtering_value, filtering_operator, adapter)
      if @options[:sql_expression]
        operator = if @options[:exact_filter]
          'exact'
        else
          %w[equals =].include?(filtering_operator) ? 'ILIKE' : 'NOT ILIKE'
        end
        WulinMaster::SqlQuery.string_query(query, @options[:sql_expression], filtering_value, self, operator)
      else
        column_type = column_type(reflection.klass, source)
        # for string column
        normal_type = %i[integer float decimal boolean date datetime].include?(column_type)
        return apply_string_filter(query, filtering_operator, filtering_value) unless source =~ /(_)?id$/ || normal_type
        # for special column,
        filtering_value = format_filtering_value(filtering_value, column_type)
        return apply_equation_filter(query, filtering_operator, filtering_value, column_type.to_s, adapter) if %w[equals not_equals].include? filtering_operator
        return apply_inclusion_filter(query, filtering_operator, filtering_value) if %w[include exclude].include? filtering_operator
      end
    end

    def apply_equation_filter(query, operator, value, column_type, adapter)
      if %w[date datetime].include? column_type
        filter_by_datetime(query, operator, "#{relation_table_name}.#{source}", value)
      elsif column_type == "boolean"
        adapter.boolean_query("#{relation_table_name}.#{source}", value, self)
        adapter.query
      else
        where_condition = {relation_table_name.to_sym => {source.to_sym => value}}
        return query.where.not(where_condition) unless operator == 'equals'
        query.where(where_condition)
      end
    end

    def filter_by_datetime(query, operator, field, value)
      sql_operator = %w[equals =].include?(operator) ? 'LIKE' : 'NOT LIKE'

      # Determine if this is a Date field (without time component)
      is_date_only = field =~ /#{model.table_name}\.(\w+)$/ &&
                     model.columns_hash[$1]&.type == :date
      date_format = WulinMaster.config.date_format == 'ja' ? 'YYYY/MM/DD' : 'DD/MM/YYYY'
      # Handle comma-separated values (e.g., "11,12,13" to match 11/*, 12/*, 13/*)
      if value.include?(',')
        values = value.split(',').map(&:strip).reject(&:empty?)

        # If no valid values after splitting, return query unchanged
        return query if values.empty?

        if is_date_only
          # For Date fields (without time), don't apply timezone conversion
          conditions = values.map { "to_char(#{field}::date, '#{date_format}') #{sql_operator} UPPER(?)" }
          params = values.map { |v| "#{v}%" }
        else
          # For DateTime/timestamp fields, apply timezone conversion
          conditions = values.map { "to_char(#{field}::timestamptz AT TIME ZONE ?, '#{date_format} HH24:MI') #{sql_operator} UPPER(?)" }
          params = values.flat_map { |v| [time_zone_offset, "#{v}%"] }
        end

        # Use OR for LIKE (equals), AND for NOT LIKE (not_equals)
        joiner = sql_operator == 'LIKE' ? ' OR ' : ' AND '
        query.where([conditions.join(joiner), *params])
      else
        if is_date_only
          # For Date fields (without time), don't apply timezone conversion
          query.where(["to_char(#{field}::date, '#{date_format}') #{sql_operator} UPPER(?)", "#{value}%"])
        else
          # For DateTime/timestamp fields, apply timezone conversion
          query.where([
            "to_char(#{field}::timestamptz AT TIME ZONE ?, '#{date_format} HH24:MI') #{sql_operator} UPPER(?)",
            time_zone_offset,
            "#{value}%"
          ])
        end
      end
    end

    def time_zone_offset
      Time.zone.tzinfo.name
    end

    def apply_inclusion_filter(query, operator, value)
      relation_class = reflection.klass
      ids = relation_class.where("#{relation_table_name}.#{source} = ?", value).map do |e|
        real_relation_name = relation_class.reflections.find { |k| k[1].klass.name == model.name }
        raise "Couldn't find relation to model #{model.name} in model #{relation_class}" if real_relation_name.nil?

        real_relation_name = real_relation_name[0]
        records = e.send(real_relation_name)
        records = [records].compact unless records.respond_to?(:map)
        records.map(&:id)
      end.flatten.uniq
      if ids.blank?
        operator = operator == 'include' ? 'IS' : 'IS NOT'
        query.where("#{model.table_name}.id #{operator} NULL")
      else
        operator = operator == 'include' ? 'IN' : 'NOT IN'
        query.where("#{model.table_name}.id #{operator} (?)", ids)
      end
    end

    def apply_string_filter(query, operator, value)
      if @options[:exact_filter]
        # For exact filter with not_equals, prefix the value with !
        if operator == 'not_equals'
          value = "!#{value}"
        end
        operator = 'exact'
      else
        operator = case operator
        when 'equals' then 'ILIKE'
        when 'not_equals' then 'NOT ILIKE'
        end
      end
      WulinMaster::SqlQuery.string_query(query, "#{relation_table_name}.#{source}", value, self, operator)
    end

    def format_filtering_value(value, column_type)
      formatted_value = case column_type
      when :integer
        value.to_i
      when :float, :decimal
        value.to_f
      when :boolean
        true_values = %w[y yes ye t true]
        true_values.include?(value.downcase)
      else
        value
      end
    end

    def filter_without_reflection(query, filtering_value, filtering_operator, column_sql_type, adapter)
      field = "#{model.table_name}.#{source}"
      match_data = filtering_value.match(/\s*(>=?|<=?|=)*\s*(.*)/)
      operator = match_data[1] || filtering_operator

      operator = "=" if operator == 'equals'
      operator = "NOT ILIKE" if operator == 'not_equals'

      text = match_data[2].strip

      case column_sql_type.to_s
      when 'date', 'datetime'
        filter_by_datetime(query, operator, field, text)
      when "boolean"
        true_values = %w[y yes ye t true]
        true_or_false = true_values.include?(filtering_value.downcase)
        adapter.boolean_query(complete_column_name, true_or_false, self, operator)
        adapter.query
      when 'enum'
        matching_keys = []
        model.send(source.to_s.pluralize).each do |key, value|
          if key.downcase.start_with?(filtering_value.downcase) ||
             model.human_enum_name(source, key).downcase.start_with?(filtering_value.downcase)
            matching_keys << value
          end
        end
        query.where(source => matching_keys.presence)
      else
        # number
        if %w[integer float decimal].include?(sql_type.to_s) &&
           table_column? &&
           operator &&
           text.match(/\A[-+]?[0-9]*\.?[0-9]+\Z/)
           operator = "<>" if operator == "NOT ILIKE"
          query.where(["#{field} #{operator} ?", text])
        # string etc.
        else
          # Use IN/NOT IN for numeric columns: matches number(,number)*
          if %w[integer float decimal].include?(sql_type.to_s) &&
             table_column? &&
             filtering_value.match?(/\A[-+]?\d*\.?\d+(,[-+]?\d*\.?\d+)*\Z/)

            values = filtering_value.split(',')
            numeric_values = sql_type.to_s == 'integer' ? values.map(&:to_i) : values.map(&:to_f)

            if filtering_operator == 'not_equals'
              return query.where.not(source => numeric_values)
            else
              return query.where(source => numeric_values)
            end
          end

          # Fall through to string_query for complex patterns (AND, null, etc.)
          if @options[:exact_filter] || %w[integer float decimal].include?(sql_type.to_s)
            # For exact filter with not_equals, we need to add ! prefix back
            if operator == 'NOT ILIKE' || filtering_operator == 'not_equals'
              filtering_value = "!#{filtering_value}"
            end
            args = [complete_column_name, filtering_value, self, 'exact']
          else
            args = [complete_column_name, filtering_value, self]
            args << operator if operator =~ /^(exact|NOT\ ILIKE)$/
          end
          adapter.string_query(*args)
          adapter.query
        end
      end
    end
  end
end
