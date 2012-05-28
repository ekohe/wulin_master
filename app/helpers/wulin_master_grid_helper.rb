module WulinMasterGridHelper
  def select_options(column)
    column.choices.is_a?(Array) ? column.choices : [] 
  end
  
  def fetch_path(column)
    column.choices.is_a?(Array) ? nil : column.choices
  end
  
  def select_tag_options(column)
    column.options[:choices].is_a?(Array) ? column.options[:choices].inject(''){|options, x| options << "<option value='#{x[:id]}'>#{x[:name]}</option>"}.html_safe : []
  end
  
  def select_tag_fetch_path(column)
    column.options[:choices].is_a?(Array) ? nil : column.options[:choices]
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
end