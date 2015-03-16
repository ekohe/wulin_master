require 'wulin_master/components/grid/column/sql_adapter'

module WulinMaster
  module ColumnFilter
    # Apply a where condition on the query to filter the result set with the filtering value
    def apply_filter(query, filtering_value, filtering_operator='equals')
      adapter = WulinMaster::SqlAdapter.new(model, query)
      filtering_operator ||= 'equals'
      return query if filtering_value.blank?

      # Search by NULL
      return filter_by_null(query, filtering_value, filtering_operator, adapter) if filtering_value.to_s.downcase == 'null'

      if reflection
        return filter_with_reflection(query, filtering_value, filtering_operator, adapter)
      else
        return filter_without_reflection(query, filtering_value, sql_type, adapter)
      end
      adapter.query
    end

    private

    def filter_by_null(query, filtering_value, filtering_operator, adapter)
      operator = case filtering_operator
      when 'equals' then ''
      when 'not_equals' then 'NOT'
      end
      if self.reflection
        return query.where("#{relation_table_name}.#{self.option_text_attribute} IS #{operator} NULL")
      else
        adapter.null_query(complete_column_name, operator, self)
        return adapter.query
      end
    end

    def filter_with_reflection(query, filtering_value, filtering_operator, adapter)
      if @options[:sql_expression]
        # Add support for multiple columns filtering
        if @options[:sql_expression].split(',').count > 1
          return query.where("UPPER(concat(#{@options[:sql_expression]})) like ?", filtering_value.upcase.gsub(/\s+/, '') + '%')
        else
          return query.where(["UPPER(cast((#{@options[:sql_expression]}) as text)) LIKE UPPER(?)", filtering_value+"%"])
        end
      else
        column_type = column_type(self.reflection.klass, self.option_text_attribute)  # this can also get from options[:inner_sql_type]
        # for special column,
        # ! need to refactor, use common code with filter_without_reflection
        if option_text_attribute =~ /(_)?id$/ or [:integer, :float, :decimal, :boolean, :date, :datetime].include? column_type
          filtering_value = format_filtering_value(filtering_value, column_type)
          if ['equals', 'not_equals'].include? filtering_operator
            return apply_equation_filter(query, filtering_operator, filtering_value, column_type.to_s, adapter)
          elsif ['include', 'exclude'].include? filtering_operator
            return apply_inclusion_filter(query, filtering_operator, filtering_value)
          end
        # for string column
        else
          return apply_string_filter(query, filtering_operator, filtering_value)
        end
      end
    end

    def apply_equation_filter(query, operator, value, column_type, adapter)
      if ['date', 'datetime'].include? column_type
        operator = (operator == 'equals') ? 'LIKE' : 'NOT LIKE'
        return query.where(["to_char(#{relation_table_name}.#{self.option_text_attribute}, 'YYYY-MM-DD') #{operator} UPPER(?)", "#{value}%"])
      elsif column_type == "boolean"
        adapter.boolean_query("#{relation_table_name}.#{self.option_text_attribute}", value, self)
        return adapter.query
      else
        operator = (operator == 'equals') ? '=' : '!='
        return query.where("#{relation_table_name}.#{self.option_text_attribute} #{operator} ?", value)
      end
    end

    def apply_inclusion_filter(query, operator, value)
      relation_class = self.reflection.klass
      ids = relation_class.where("#{relation_table_name}.#{self.option_text_attribute} = ?", value).map do |e|
        real_relation_name = relation_class.reflections.find { |k| k[1].klass.name == model.name }[0]
        e.send(real_relation_name).map(&:id)
      end.flatten.uniq
      if ids.blank?
        operator = (operator == 'include') ? 'IS' : 'IS NOT'
        return query.where("#{model.table_name}.id #{operator} NULL")
      else
        operator = (operator == 'include') ? 'IN' : 'NOT IN'
        return query.where("#{model.table_name}.id #{operator} (?)", ids)
      end
    end

    def apply_string_filter(query, operator, value)
      operator = case operator
      when 'equals' then 'LIKE'
      when 'not_equals' then 'NOT LIKE'
      end
      return query.where(["UPPER(cast(#{relation_table_name}.#{self.option_text_attribute} as text)) #{operator} UPPER(?)", value + "%"])
    end

    def format_filtering_value(value, column_type)
      formatted_value = if column_type == :integer
        value.to_i
      elsif column_type == :float or column_type == :decimal
        filtering_value.to_f
      elsif column_type == :boolean
        true_values = ["y", "yes", "ye", "t", "true"]
        true_values.include?(value.downcase)
      end
    end

    def filter_without_reflection(query, filtering_value, column_sql_type, adapter)
      case column_sql_type.to_s
      when 'date', 'datetime'
        return query.where(["to_char(#{self.name}, 'YYYY-MM-DD') LIKE UPPER(?)", filtering_value+"%"])
      when "boolean"
        true_values = ["y", "yes", "ye", "t", "true"]
        true_or_false = true_values.include?(filtering_value.downcase)
        adapter.boolean_query(complete_column_name, true_or_false, self)
        return adapter.query
      else
        filtering_value = filtering_value.gsub(/'/, "''")
        if ['integer', 'float', 'decimal'].include? sql_type.to_s and is_table_column?
          return query.where(self.name => filtering_value)
        else
          adapter.string_query(complete_column_name, filtering_value, self)
          return adapter.query
        end
      end
    end

  end
end