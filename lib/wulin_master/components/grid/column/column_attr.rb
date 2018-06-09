# frozen_string_literal: true

module WulinMaster
  module ColumnAttr
    def assign_attribute(_object, value, new_attrs, attrs, type)
      if relation_field?
        attrs.delete(field_str) # Must remove the old one
        if type == :create
          assign_relation_attr_for_create(new_attrs, value)
        elsif type == :update
          assign_relation_attr_for_update(new_attrs, value)
        end
      elsif value.blank? # v == 'null'
        new_attrs[field_sym] = nil
      end
    end

    def model_associations
      @model_associations ||= model.reflections
    end

    private

    def assign_relation_attr_for_create(new_attrs, value)
      if relation_macro == :belongs_to
        if value.is_a?(String)
          new_attrs[relation_object.foreign_key] = value
        elsif value.is_a?(Hash) && value['id'] && (value['id'] != 'null')
          new_attrs[relation_object.foreign_key] = value['id']
        end
      elsif relation_macro.match?(/^has_many$|^has_and_belongs_to_many$/)
        if (value == 'null') || value.blank?
          new_attrs[field_sym] = []
        elsif value.is_a?(Array)
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
        assign_has_many_attr(new_attrs, value)
      when :has_one then
        assign_has_one_attr(new_attrs, value)
      end
    end

    def assign_belongs_to_attr(new_attrs, association_attributes)
      if association_attributes['id'].blank? || (association_attributes['id'] == 'null')
        new_attrs[relation_object.foreign_key] = nil
      elsif association_attributes['id'].present?
        new_attrs[relation_object.foreign_key] = association_attributes['id']
      elsif one_reverse_relation?(relation_object.klass, model)
        nested_attr_key = (field_str.match?(/_attributes$/) ? field_str : "#{k}_attributes")
        new_attrs[nested_attr_key] = association_attributes
      end
    end

    def assign_habtm_attr(new_attrs, association_attributes)
      # batch update action will pass id with array like ['1', '2'], not hash like { id => ['1', '2']}
      the_ids = if association_attributes.is_a?(Array)
        association_attributes # .first.split(',')
      elsif association_attributes.is_a?(Hash) || association_attributes.is_a?(ActionController::Parameters)
        ((association_attributes['id'] == 'null') || association_attributes['id'].blank? ? [] : association_attributes['id'])
      else
        []
      end
      the_ids = the_ids.uniq.delete_if(&:blank?)
      new_attrs[field_sym] = if the_ids.blank?
        []
      else
        relation_object.klass.find(the_ids).to_a
      end
    end

    def assign_has_many_attr(new_attrs, association_attributes)
      # Should convert association_attributes for grid cell editor ajax request.
      if association_attributes.is_a?(Hash) && association_attributes.values.all? { |value| value.key?('id') }
        association_attributes = association_attributes.values.map { |x| x['id'] }.uniq.delete_if(&:blank?)
      end

      association_attributes = association_attributes['id'] || 'null' if association_attributes.is_a?(ActionController::Parameters)

      new_attrs[field_sym] = if (association_attributes == 'null') || association_attributes.all? { |value| value == 'null' }
        []
      else
        relation_object.klass.find(association_attributes.uniq.delete_if(&:blank?)).to_a
      end
    end

    def assign_has_one_attr(new_attrs, association_attributes)
      if association_attributes.is_a?(Hash) && association_attributes.values.all? { |value| value.key?('id') }
        association_attributes = association_attributes.values.map { |x| x['id'] }.uniq.delete_if(&:blank?)
      end

      association_attributes = association_attributes['id'] || 'null' if association_attributes.is_a?(ActionController::Parameters)

      new_attrs[field_sym] = if association_attributes == 'null'
        nil
      else
        relation_object.klass.find(association_attributes)
      end
    end

    def field_str
      @field_str ||= (options[:through] || name).to_s
    end

    def field_sym
      @field_sym ||= (options[:through] || name).to_sym
    end

    def relation_macro
      @relation_macro ||= relation_object.macro
    end

    def relation_object
      @relation_object ||= model_associations[field_str]
    end

    def one_reverse_relation?(related_klass, klass)
      (reflect = related_klass.reflections.find { |x| x[1].klass == klass }[1]) && (reflect.macro == :has_one)
    end

    def relation_field?
      model_associations.key?(field_str)
    end
  end
end
