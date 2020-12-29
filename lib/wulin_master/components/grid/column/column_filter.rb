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
      query.where("#{relation_table_name}.#{source} IS #{operator} NULL")
    end

    def filter_with_reflection(query, filtering_value, filtering_operator, adapter)
      if @options[:sql_expression]
        query.where(["UPPER(cast((#{@options[:sql_expression]}) as text)) LIKE UPPER(?)", filtering_value + "%"])
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
      operator = %w[equals =].include?(operator) ? 'LIKE' : 'NOT LIKE'
      query.where(["to_char(#{field}, 'DD/MM/YYYY HH24:MI:SS') #{operator} UPPER(?)", "#{value}%"])
    end

    def apply_inclusion_filter(query, operator, value)
      relation_class = reflection.klass
      ids = relation_class.where("#{relation_table_name}.#{source} = ?", value).map do |e|
        real_relation_name = relation_class.reflections.find { |k| k[1].klass.name == model.name }
        raise "Couldn't find relation to model #{model.name} in model #{relation_class}" if real_relation_name.nil?

        real_relation_name = real_relation_name[0]
        e.send(real_relation_name).map(&:id)
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
      operator = case operator
      when 'equals' then 'LIKE'
      when 'not_equals' then 'NOT LIKE'
      end
      query.where(["UPPER(cast(#{relation_table_name}.#{source} as text)) #{operator} UPPER(?)", value + "%"])
    end

    def format_filtering_value(value, column_type)
      formatted_value = if column_type == :integer
        value.to_i
      elsif (column_type == :float) || (column_type == :decimal)
        value.to_f
      elsif column_type == :boolean
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

      text = match_data[2].strip

      case column_sql_type.to_s
      when 'date', 'datetime'
        filter_by_datetime(query, operator, field, text)
      when "boolean"
        true_values = %w[y yes ye t true]
        true_or_false = true_values.include?(filtering_value.downcase)
        adapter.boolean_query(complete_column_name, true_or_false, self)
        adapter.query
      when 'enum'
        filtering_value = model.send(source.to_s.pluralize).find do |key, value|
          value if key.downcase.start_with?(filtering_value.downcase)
        end
        query.where(source => filtering_value)
      else
        # number
        if %w[integer float decimal].include?(sql_type.to_s) &&
           table_column? &&
           operator &&
           text.match(/\A[-+]?[0-9]*\.?[0-9]+\Z/)
          query.where(["#{field} #{operator} ?", text])
        # string etc.
        else
          adapter.string_query(complete_column_name, filtering_value, self)
          adapter.query
        end
      end
    end
  end
end
