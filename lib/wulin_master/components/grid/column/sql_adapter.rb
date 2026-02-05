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

    def string_query(query, column_name, filter, column, operator = "ILIKE")
      # Opt-in normalization: only normalize if column has normalize_query: true
      # This avoids expensive normalize_japanese_sql() computation on columns that don't need it
      normalize_query = column&.options&.dig(:normalize_query)

      # Check if this is a customer name column that can use the materialized normalized_full_name
      is_customer_name = column_name =~ /customers\.(last_name|first_name)/ ||
                         column_name.include?("customers.last_name || ' ' || customers.first_name")

      # Get the model class from the ActiveRecord::Relation
      model_class = query.respond_to?(:klass) ? query.klass : query

      if normalize_query && is_customer_name && model_class.reflect_on_association(:customer)
        # Use materialized column for customer names
        normalized_column = "customers.normalized_full_name"
      elsif normalize_query
        # Use normalize_japanese_sql for other columns that need it
        normalized_column = "normalize_japanese_sql(CAST(#{column_name} AS TEXT))"
      else
        # Default: use column directly (fast, index-friendly)
        normalized_column = column_name
      end

      if filter.start_with?("\"") && filter.end_with?("\"")
        filter = filter[1..-2]
        # Only normalize search term if normalize_query is enabled
        normalized_filter = normalize_query ? normalize_search_term(filter) : filter
        return query.where(["#{normalized_column} ILIKE ?", "#{normalized_filter}%"])
      end

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

      # If no valid filter parts remain after cleaning, return query unchanged
      return query if parts.empty?

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
          # Only normalize search term if normalize_query is enabled
          normalized_value = normalize_query ? normalize_search_term(value) : value
          if normalize_query && is_customer_name && model_class.reflect_on_association(:customer)
            conditions << "(#{normalized_column} NOT ILIKE ? OR #{normalized_column} IS NULL)"
          else
            conditions << "(#{normalized_column} NOT ILIKE ? OR #{column_name} IS NULL)"
          end
          query_params << "#{normalized_value}%"
        else
          # Only normalize search term if normalize_query is enabled
          normalized_part = normalize_query ? normalize_search_term(part) : part
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
