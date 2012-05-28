module WulinMasterGridHelper
  def select_options(column)
    # column.choices.is_a?(Array) ? column.choices : [] 
    if column.choices.is_a?(Array)
      column.choices
    elsif column.choices.is_a?(Hash) # TODO: support hash options
      []
    else
      []
    end
  end
  
  def fetch_path(column)
    column.choices.is_a?(String) ? column.choices : nil
  end
  
  def select_tag_options(column)
    # column.options[:choices].is_a?(Array) ? column.options[:choices].inject(''){|options, x| options << "<option value='#{x[:id]}'>#{x[:name]}</option>"}.html_safe : []
    if column.options[:choices].is_a?(Array)
      column.options[:choices].inject(''){|options, x| options << "<option value='#{x[:id]}'>#{x[:name]}</option>"}.html_safe
    elsif column.options[:choices].is_a?(Hash) # TODO: support hash options
      []
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
end