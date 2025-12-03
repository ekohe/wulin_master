module WulinMaster
  module EnumI18n
    extend ActiveSupport::Concern

    class_methods do
      def human_enum_name(enum_name, enum_value)
        plural_key   = :"activerecord.attributes.#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}"
        singular_key = :"activerecord.attributes.#{model_name.i18n_key}.#{enum_name}.#{enum_value}"
        alt_plural   = :"#{model_name.i18n_key}.#{enum_name.to_s.pluralize}.#{enum_value}"
        alt_singular = :"#{model_name.i18n_key}.#{enum_name}.#{enum_value}"
        I18n.t(plural_key, default: [singular_key, alt_plural, alt_singular, enum_value.to_s.humanize])
      end

      def human_enum_options(enum_name)
        send(enum_name.to_s.pluralize).map { |key, _| [human_enum_name(enum_name, key), key] }
      end
    end

    def human_enum_name(enum_name)
      self.class.human_enum_name(enum_name, send(enum_name))
    end
  end
end

ActiveSupport.on_load(:active_record) do
  include WulinMaster::EnumI18n
end


