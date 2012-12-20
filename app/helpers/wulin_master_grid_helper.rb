module WulinMasterGridHelper
  def select_options(column)
    choices = column.options[:choices]
    if choices.is_a?(Array)
      choices.map{|o| o.is_a?(Hash) ? [o[:name], o[:id]] : o }
    elsif choices.is_a?(Proc)
      choices.call
    else
      []
    end
  end

  def select_tag_options(column)
    choices = column.options[:choices]
    if choices.is_a?(Array)
      array_to_options(choices)
    elsif choices.is_a?(Proc)
      array_to_options(choices.call)
    elsif choices.is_a?(Hash) # TODO: support hash options
      choices.map{|k,v| v.inject("<option value=''></option>"){|str, e| str << "<option value='#{e}' data-key='#{k}' style='display:none'>#{e}</option>"}}.inject(""){|options, x| options << x}.html_safe
    else
      []
    end
  end

  def date_column?(column)
    'true' if column.sql_type.to_s.downcase == 'date' and !column.options[:simple_date] and !column.options[:simple_time]
  end

  def datetime_column?(column)
    'true' if column.sql_type.to_s.downcase == 'datetime' and !column.options[:simple_date] and !column.options[:simple_time]
  end

  def time_column?(column)
    'true' if column.options[:editor] == 'TimeCellEditor' and !column.options[:simple_date] and !column.options[:simple_time]
  end
  
  def get_column_name(column)
    if column.sql_type.to_s == 'has_and_belongs_to_many' or column.sql_type.to_s == 'has_many'
      column.reflection.name.to_s
    else
      column.form_name
    end
  end

  def grid_states_options(user_id, grid_name)
    states = WulinMaster::GridState.for_user_and_grid(user_id, grid_name).all
    return [] if states.blank?
    current = WulinMaster::GridState.current(user_id, grid_name)
    states.delete(current)
    states.unshift(current).compact.map{|x| [x.name, x.id]}
  end

  def new_form_able?(column)
    formable = column.options[:formable]
    return true if formable.nil?
    if formable
      Array === formable ? formable.include?(:new) : !!formable
    else
      false
    end
  end

  def edit_form_able?(column)
    formable = column.options[:formable]
    editable = column.options[:editable]
    return false if FalseClass === editable
    if editable or editable.nil?
      return true if formable.nil?
      if formable
        Array === formable ? formable.include?(:edit) : !!formable
      else
        false
      end
    end
  end

  def clean_up_for(column)
    column_name = get_column_name(column)
    clean_up_tag(column_name) if column.presence_required?
  end

  def clean_up_tag(column_name)
    content_tag(:abbr, nil, class: 'input_clean_up', data: {target: "#{column_name}_target_flag"})
  end

  def array_to_options(arr)
    arr.map!{|o| o.is_a?(Hash) ? o : {:id => o, :name => o} }
    arr.inject(''){|options, x| options << "<option value='#{x[:id]}'>#{x[:name]}</option>"}.html_safe
  end

end