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

      # Replace consecutive `,` with a single comma and consecutive `&` with a single ampersand
      cleaned_str = cleaned_str.gsub(/,{2,}/, ",").gsub(/&{2,}/, "&")

      cleaned_str = cleaned_str.gsub(/,&/, ",").gsub(/&,/, "&")

      # Remove trailing `,` or `&` if it exists at the end of the string (optional whitespace before it)
      cleaned_str.gsub(/[,&]$/, "")
    end

    def normalize_search_term(term)
      # Normalize the search term using the database function
      # This ensures consistent comparison between search terms and column values
      #  We use sanitize_sql_array to avoid prepared statement issues with user-defined functions
      sql = ActiveRecord::Base.sanitize_sql_array(["SELECT normalize_japanese_sql(?)", term])
      ActiveRecord::Base.connection.select_value(sql)
    rescue
      # If normalization fails, return the original term
      term
    end

    def string_query(query, column_name, filter, _, operator = "ILIKE")
      # Use materialized normalized_full_name column if querying customer name via customers table
      # This avoids expensive normalize_japanese_sql() computation on every row
      use_normalized_column = column_name =~ /customers\.(last_name|first_name)/ || 
                               column_name.include?("customers.last_name || ' ' || customers.first_name")
      
      # Get the model class from the ActiveRecord::Relation
      model_class = query.respond_to?(:klass) ? query.klass : query
      
      if use_normalized_column && model_class.reflect_on_association(:customer)
        # Replace the computed expression with the materialized column
        normalized_column = "customers.normalized_full_name"
      else
        normalized_column = "normalize_japanese_sql(CAST(#{column_name} AS TEXT))"
      end

      if filter.start_with?("\"") && filter.end_with?("\"")
        filter = filter[1..-2]
        # Normalize the search pattern for consistent comparison
        normalized_filter = normalize_search_term(filter)
        return query.where(["#{normalized_column} ILIKE ?", "#{normalized_filter}%"])
      end

      # filter will be recovered from #transform_if_exclamation_not_equal
      uncensored_filter = case operator
      when /NOT ILIKE/i
        clean_special_chars "!#{filter}"
      when /ILIKE/i
        clean_special_chars filter
      end

      conditions = []
      query_params = []

      parts = uncensored_filter.split(/([,&])/).reject { |s| s.empty? }
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
          # Normalize the search value for consistent comparison
          normalized_value = normalize_search_term(value)
          if use_normalized_column && model_class.reflect_on_association(:customer)
            conditions << "(#{normalized_column} NOT ILIKE ? OR #{normalized_column} IS NULL)"
          else
            conditions << "(#{normalized_column} NOT ILIKE ? OR #{column_name} IS NULL)"
          end
          query_params << "#{normalized_value}%"
        else
          # Normalize the search pattern for consistent comparison
          normalized_part = normalize_search_term(part)
          conditions << "#{normalized_column} ILIKE ?"
          query_params << "#{normalized_part}%"
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

    module_function :null_query, :boolean_query, :string_query, :clean_special_chars, :normalize_search_term
  end
end
