module WulinMasterGridHelper
  def select_options(column)
    if column.choices.is_a?(Array)
      column.choices.map{|o| {:id => o, :name => o}}
    else
      []
    end
  end
  
  def fetch_path(column)
    column.choices.is_a?(String) ? column.choices : nil
  end
  
  def select_tag_options(column)
    if column.options[:choices].is_a?(Array)
      column.options[:choices].map{|o| {:id => o, :name => o}}.inject(''){|options, x| options << "<option value='#{x[:id]}'>#{x[:name]}</option>"}.html_safe
    elsif column.options[:choices].is_a?(Hash) # TODO: support hash options
      column.options[:choices].map{|k,v| v.inject("<option value=''></option>"){|str, e| str << "<option value='#{e}' data-key='#{k}' style='display:none'>#{e}</option>"}}.inject(""){|options, x| options << x}.html_safe
    else
      []
    end
  end
  
  def select_tag_fetch_path(column)
    column.options[:choices].is_a?(String) ? column.options[:choices] : nil 
  end
  
  def date_column?(column)
    'true' if column.sql_type.to_s.downcase == 'date'
  end
  
  def datetime_column?(column)
    'true' if column.sql_type.to_s.downcase == 'datetime'
  end

  def time_column?(column)
    'true' if column.options[:editor] == 'TimeCellEditor'
  end

  def default_hour(column)
    column.options[:default_hour]
  end

  def default_minute(column)
    column.options[:default_minute]
  end
end