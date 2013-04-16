module WulinMaster
  module ColumnAttr

    def assign_attribute(object, value, new_attrs, attrs, type)
      if relation_field?
        attrs.delete(field_str) # Must remove the old one
        if type == :create
          assign_relation_attr_for_create(new_attrs, value)
        elsif type == :update
          assign_relation_attr_for_update(new_attrs, value)
        end
      elsif options[:simple_date]
        assign_simple_date_attr(new_attrs, value, object)
      elsif options[:simple_time]
        assign_simple_time_attr(new_attrs, value, object)
      elsif invalid_attr?
        attrs.delete_if {|key, value| key.to_s == field_str }
      elsif value.blank?  #v == 'null'
        new_attrs[field_sym] = nil
      end
    end

    def model_associations
      @model_associations ||= self.model.reflections
    end

    def simple_date_format(value)
      Date.parse("#{value} #{WulinMaster.config.default_year}")
    rescue Exception => e
      nil
    end
    module_function :simple_date_format

    private

    def assign_simple_date_attr(new_attrs, value, object)
      if object and value.present?
        new_date = simple_date_format(value)
        if new_date.nil?
          new_attrs[field_sym] = nil
        else
          value_was = object.__send__("#{field_str}_was").try(:to_date)
          new_attrs[field_sym] = (value_was.blank? ? new_date.to_s : value_was.change(year: new_date.year, month: new_date.month, day: new_date.day).to_s)
        end
      else
        new_attrs[field_sym] = simple_date_format(value)
      end
    end

    def assign_simple_time_attr(new_attrs, value, object)
      if object and value.present?
        value_was = object.__send__("#{field_str}_was")
        begin
          new_time = Time.parse(value)
          new_attrs[field_sym] = (value_was.blank? ? value : value_was.change(hour: new_time.hour, min: new_time.min))
        rescue Exception => e
          new_attrs[field_sym] = nil
        end
      else
        new_attrs[field_sym] = value
      end
    end

    def assign_relation_attr_for_create(new_attrs, value)
      if relation_macro == :belongs_to
        if String === value
          new_attrs[relation_object.foreign_key] = value
        elsif Hash === value and value['id'] and value['id'] != 'null'
          new_attrs[relation_object.foreign_key] = value['id']
        end
      elsif relation_macro =~ /^has_many$|^has_and_belongs_to_many$/
        if value == 'null' or value.blank?
          new_attrs[field_sym] = []
        elsif Array === value
          value = value.uniq.delete_if(&:blank?)
          new_attrs[field_sym] = relation_object.klass.find(value).to_a
        end
      end
    end

    def assign_relation_attr_for_update(new_attrs, value)
      case relation_macro
      when :belongs_to then
        assign_belongs_to_attr(new_attrs, value)
      when :has_and_belongs_to_many then
        assign_habtm_attr(new_attrs, value)
      when :has_many then
        assign_has_many_attr(new_attrs,value)
      end
    end

    def assign_belongs_to_attr(new_attrs, association_attributes)
      if association_attributes['id'].blank? or association_attributes['id'] == 'null'
        new_attrs[relation_object.foreign_key] = nil
      elsif association_attributes['id'].present?
        new_attrs[relation_object.foreign_key] = association_attributes['id']
      elsif has_one_reverse_relation?(relation_object.klass, model)
        nested_attr_key = (field_str =~ /_attributes$/ ? field_str : "#{k}_attributes")
        new_attrs[nested_attr_key] = association_attributes
      end
    end

    def assign_habtm_attr(new_attrs, association_attributes)
      # batch update action will pass id with array like ['1', '2'], not hash like { id => ['1', '2']}
      if Array === association_attributes
        the_ids = association_attributes#.first.split(',')
      elsif Hash === association_attributes
        the_ids = ((association_attributes['id'] == 'null' or association_attributes['id'].blank?) ? [] : association_attributes['id'])
      else
        the_ids = []
      end
      the_ids = the_ids.uniq.delete_if(&:blank?)
      if the_ids.blank?
        new_attrs[field_sym] = []
      else
        new_attrs[field_sym] = relation_object.klass.find(the_ids).to_a
      end
    end

    def assign_has_many_attr(new_attrs,association_attributes)
      # Should convert association_attributes for grid cell editor ajax request.
      if Hash === association_attributes and association_attributes.values.all? {|value| value.key?('id')}
         association_attributes = association_attributes.values.map{|x| x['id']}.uniq.delete_if(&:blank?)
      end
      if association_attributes == 'null' or association_attributes.all? {|value| value == 'null'}
        new_attrs[field_sym] = []
      else
        new_attrs[field_sym] = relation_object.klass.find(association_attributes.uniq.delete_if(&:blank?)).to_a
      end
    end

    def field_str
      @field_str ||= self.name.to_s
    end

    def field_sym
      @field_sym ||= self.name.to_sym
    end

    def relation_macro
      @relation_macro ||= relation_object.macro
    end

    def relation_object
      @relation_object ||= model_associations[field_sym]
    end

    def has_one_reverse_relation?(related_klass, klass)
      (reflect = related_klass.reflections.find{|x| x[1].klass == klass}[1]) and reflect.macro == :has_one
    end

    def invalid_attr?
      if is_hstore?
        !field_str.index('->')
      else
        (field_str !~ /_attributes$/ and model_columns.exclude?(field_str) and !model.public_method_defined?("#{field_str}="))
      end
    end

    def relation_field?
      model_associations.keys.include?(field_sym)
    end

  end
end