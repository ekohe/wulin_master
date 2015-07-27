module WulinMaster
  class SqlAdapter
    attr_accessor :model, :query

    def initialize(model, query)
      @model = model
      @query = query
    end

    %w(null_query boolean_query string_query).each do |method_name|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method_name}(column_name, value, column)
          if model < ActiveRecord::Base
            @query = SqlQuery.#{method_name}(@query, column_name, value, column)
          else
            @query = NoSqlQuery.#{method_name}(@query, column_name, value, column)
          end
        end
      RUBY
    end
  end

  module SqlQuery
    def null_query(query, column_name, value, column)
      query.where("#{column_name} IS #{value} NULL")
    end

    def boolean_query(query, column_name, value, column)
      if (column.options[:formatter] == 'YesNoCellFormatter' or column.options[:inner_formatter] == 'YesNoCellFormatter') and !value
        query.where("#{column_name} = ? OR #{column_name} is NULL", 'f')
      else
        query.where(column_name => value)
      end
    end

    def string_query(query, column_name, value, column)
      query.where(["UPPER(cast((#{column_name}) as text)) LIKE UPPER(?)", value+"%"])
    end

    module_function :null_query, :boolean_query, :string_query
  end

  module NoSqlQuery
    def null_query(query, column_name, value, column)
      # query.where("name IS #{value} NULL")
      if value == 'NOT'
        query.where(column_name.to_sym.ne => "", column_name.to_sym.exists => true)
      else
        query.where(column_name.to_sym.eq => "", column_name.to_sym.exists => false)
      end
    end

    def boolean_query(query, column_name, value, column)
      if value
        query.where(column.name => true)
      else
        query.any_in(column.name => [nil, false])
      end
    end

    def string_query(query, column_name, value, column)
      if column.options[:type] == 'Datetime' and (datetime_range = format_datetime(value)).present?
        query.where(
        column.name.to_sym.gte => datetime_range[:from],
        column.name.to_sym.lte => datetime_range[:to]
        )
      else
        query.where(column.name => Regexp.new("#{Regexp.escape(value)}.*", true))
      end
    end


    def self.format_datetime(datetime)
      case datetime
      when /^\d{1,4}-?$/ # 20 2011 2011-
        year = datetime.first(4)
        from_year = year.size <=3 ? (year + '0' * (4 - 1 - year.size) + '1') : year
        to_year = year + '9' * (4 - year.size)
        { from: build_datetime(from_year.to_i), to: build_datetime(to_year.to_i, 12, 31, 23, 59, 59) }
      when /^\d{1,4}-[0-1]$/ # 2011-0 - 2011-1
        year, month = extract_data(datetime)
        if month == 0
          { from: build_datetime(year), to: build_datetime(year, 9, 30, 23, 59, 59) }
        elsif month == 1
          { from: build_datetime(year, 10), to: build_datetime(year, 12, 31, 23, 59, 59) }
        end
      when /^\d{1,4}-(0[1-9]|1[0-1])-?$/ # 2011-01 - 2011-09  or  2011-10 - 2011-11
        year, month = datetime.first(7).split('-').map(&:to_i)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month), to: build_datetime(year, month, 31, 23, 59, 59) }
        else
          { from: build_datetime(year, month), to: build_datetime(year, month, 30, 23, 59, 59) }
        end
      when /^\d{1,4}-12-?$/ # 2011-12
        year = datetime.first(4).to_i
        { from: build_datetime(year, 12), to: build_datetime(year, 12, 31, 23, 59, 59) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-0$/ # 2011-12-0
        year, month, date = extract_data(datetime)
        { from: build_datetime(year, month, 1), to: build_datetime(year, month, 9, 23, 59, 59) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-[1-2]$/ # 2011-12-1 2011-12-2
        year, month, date = extract_data(datetime)
        { from: build_datetime(year, month, date * 10), to: build_datetime(year, month, (date * 10) + 9, 23, 59, 59) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-[3]$/ # 2011-12-3
        year, month, date = extract_data(datetime)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 31, 23, 59, 59) }
        else
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 30, 23, 59, 59) }
        end
      when /^\d{1,4}-(0[1-9]|1[0-2])-3[0-1]\s?$/ # 2011-12-31  2011-11-30
        year, month, date = extract_data(datetime)
        if [1,3,5,7,8,10,12].include? month
          { from: build_datetime(year, month, date), to: build_datetime(year, month, date, 23, 59, 59) }
        elsif date == 30
          { from: build_datetime(year, month, 30), to: build_datetime(year, month, 30, 23, 59, 59) } # 2011-12-30 - 2011-12-30
        end
      when /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s?$/ # 2011-12-01 - 2011-12-29
        year, month, date = extract_data(datetime)
        { from: build_datetime(year, month, date), to: build_datetime(year, month, date, 23, 59, 59) }
        # Time part
      when /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s[0-1]$/ # 2011-11-11 0   2011-11-11 1
        year, month, date = extract_data(datetime, 0)
        hour =  datetime.split(/\s/)[1]
        { from: build_datetime(year, month, date, (hour + '0').to_i), to: build_datetime(year, month, date, (hour + '9').to_i, 59, 59) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s2$/ # 2011-11-11 2
        year, month, date = extract_data(datetime, 0)
        { from: build_datetime(year, month, date, 20), to: build_datetime(year, month, date, 23, 59, 59) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):?$/ # 2011-11-11 23   2011-11-11 23:
        year, month, date = extract_data(datetime, 0)
        hour = datetime.split(/\s/)[1].first(2).to_i
        { from: build_datetime(year, month, date, hour), to: build_datetime(year, month, date, hour, 59, 59) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):[0-5]$/ # 2011-11-11 23:0   2011-11-11 23:5
        year, month, date = extract_data(datetime, 0)
        hour, minute = datetime.split(/\s/)[1].split(':')
        { from: build_datetime(year, month, date, hour.to_i, (minute + '0').to_i), to: build_datetime(year, month, date, hour.to_i, (minute + '9').to_i, 59) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):[0-5][0-9]:?$/ # 2011-11-11 23:00   2011-11-11 23:59
        year, month, date = extract_data(datetime, 0)
        hour, minute = datetime.split(/\s/)[1].split(':').map(&:to_i)
        { from: build_datetime(year, month, date, hour, minute), to: build_datetime(year, month, date, hour, minute, 59) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5]$/ # 2011-11-11 23:24:0    2011-11-11 23:24:5
        year, month, date = extract_data(datetime, 0)
        hour, minute, second = datetime.split(/\s/)[1].split(':').map(&:to_i)
        { from: build_datetime(year, month, date, hour, minute, (second.to_s + '0').to_i), to: build_datetime(year, month, date, hour, minute, (second.to_s + '9').to_i) }
      when /^\d{1,4}-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9])\s([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9].*$/ # 2011-11-11 23:24:04    2011-11-11 23:24:54
        datetime = datetime.first(19)
        year, month, date = extract_data(datetime, 0)
        hour, minute, second = datetime.split(/\s/)[1].split(':').map(&:to_i)
        { from: build_datetime(year, month, date, hour, minute, second), to: build_datetime(year, month, date, hour, minute, second) }
      else
        {}
      end
    end

    def self.extract_data(datetime, index=nil)
      if index
        datetime.split(/\s/)[index.to_i].split('-').map(&:to_i)
      else
        datetime.split('-').map(&:to_i)
      end
    end

    def self.build_datetime(*args)
      DateTime.new(*args) rescue nil
    end


    module_function :null_query, :boolean_query, :string_query
  end

end