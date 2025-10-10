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

    def clean_special_chars(str)
      # remove all \s
      cleaned_str = str.split(/([,&])/).select { |e| e.present? }.map { |e| e.strip }.join

      # Normalize operator combinations (,& or &,) and consecutive operators to a single operator
      # Loop until no more replacements are made to handle patterns like &,&,& or ,&,&,
      loop do
        before = cleaned_str
        cleaned_str = cleaned_str.gsub(/,&/, ",").gsub(/&,/, "&")
        cleaned_str = cleaned_str.gsub(/,{2,}/, ",").gsub(/&{2,}/, "&")
        break if cleaned_str == before
      end

      # Remove trailing `,` or `&` if it exists at the end of the string (optional whitespace before it)
      cleaned_str.gsub(/[,&]$/, "")
    end

    def string_query(query, column_name, filter, _, operator = "ILIKE")
      # filter will be recovered from #transform_if_exclamation_not_equal
      uncensored_filter = case operator
      when /NOT ILIKE/i
        clean_special_chars "!#{filter}"
      when /ILIKE/i, /exact/i
        clean_special_chars filter
      end

      conditions = []
      query_params = []

      parts = uncensored_filter.split(/([,&])/).reject { |s| s.empty? }

      # Remove head if it's a comma or ampersand
      parts.shift if parts.first&.match?(/^[,&]$/)

      # Remove tail if it's a comma or ampersand
      parts.pop if parts.last&.match?(/^[,&]$/)

      parts.each do |part|
        case part
        when /,/
          conditions << " OR "
        when /&/
          conditions << " AND "
        when /^null$/i
          conditions << "#{column_name} IS NULL"
        when /^!null$/i
          conditions << "#{column_name} IS NOT NULL"
        when /^!/
          value = part[1..]
          if operator =~ /exact/i
            # If the value starts or ends with %, use NOT LIKE for pattern matching, otherwise use exact <>
            if value.start_with?('%') || value.end_with?('%')
              conditions << "(CAST(#{column_name} AS TEXT) NOT LIKE ? OR #{column_name} IS NULL)"
              query_params << value
            else
              conditions << "(CAST(#{column_name} AS TEXT) <> ? OR #{column_name} IS NULL)"
              query_params << value
            end
          else
            conditions << "(CAST(#{column_name} AS TEXT) NOT ILIKE ? OR #{column_name} IS NULL)"
            query_params << "#{value}%"
          end
        else
          if operator =~ /exact/i
            # If the value starts or ends with %, use LIKE for pattern matching, otherwise use exact =
            if part.start_with?('%') || part.end_with?('%')
              conditions << "CAST(#{column_name} AS TEXT) LIKE ?"
              query_params << part
            else
              conditions << "CAST(#{column_name} AS TEXT) = ?"
              query_params << part
            end
          else
            conditions << "CAST(#{column_name} AS TEXT) ILIKE ?"
            query_params << "#{part}%"
          end
        end
      end

      censored_conditions = [conditions.shift]
      conditions.each_slice(2) do |op, condition|
        if op =~ /OR|AND/i && condition.present?
          censored_conditions << op
          censored_conditions << condition
        end
      end

      query.where([censored_conditions.join, *query_params])
    end

    module_function :null_query, :boolean_query, :string_query, :clean_special_chars
  end
end
