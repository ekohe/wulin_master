# frozen_string_literal: true

module WulinMaster
  class SqlAdapter
    attr_accessor :model, :query

    def initialize(model, query)
      @model = model
      @query = query
    end

    %w[null_query boolean_query string_query].each do |method_name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}(column_name, value, column, *operator)
          if model < ActiveRecord::Base
            @query = SqlQuery.#{method_name}(@query, column_name, value, column, *operator)
          end
        end
      RUBY
    end
  end

  module SqlQuery
    def null_query(query, column_name, value, _column)
      query.where("#{column_name} IS #{value} NULL")
    end

    def boolean_query(query, column_name, value, column, operator = false)
      if ((column.options[:formatter] == "YesNoCellFormatter") || (column.options[:inner_formatter] == "YesNoCellFormatter")) && !value
        query.where("#{column_name} = ? OR #{column_name} is NULL", "f")
      else
        case operator
        when "NOT ILIKE"
          query.where("#{column_name} <> ?", value)
        else
          query.where(column_name => value)
        end
      end
    end

    def string_query(query, column_name, value, _column, operator = "ilike")
      logic_operator_sym = (sym = value.match(/[,&]/)) ? sym[0] : "&" # ',' or '&'
      logic_operator = logic_operator_sym == "," ? " OR " : " AND "
      logic_operator = " AND " if logic_operator_sym == "," && operator == "NOT ILIKE"
      values = value.split(/\s*#{logic_operator_sym}\s*/)

      case value
      when /^&+$/
        values = %w[&]
      when /^,+$/
        values = %w[,]
      end

      if operator == 'exact'
        query_values = values
        operator = 'ilike'
      else
        query_values = values.map { |v| "#{v}%" }
      end
      query_conditions = values.map { |_v| "cast((#{column_name}) as text) #{operator} ?" }.join(logic_operator)
      query_array = [*query_conditions, *query_values]
      query.where(query_array)
    end

    module_function :null_query, :boolean_query, :string_query
  end
end
