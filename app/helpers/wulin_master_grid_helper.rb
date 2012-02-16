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
end