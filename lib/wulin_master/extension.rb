module ActiveRecord::Associations::Builder
  class HasMany < CollectionAssociation
    private

    def define_restrict_dependency_method
      name = self.name
      mixin.redefine_method(dependency_method_name) do
        has_one_macro = association(name).reflection.macro == :has_one
        if has_one_macro ? !send(name).nil? : send(name).exists?
          errors.add(:base, I18n.t("activerecord.errors.messages.restrict_dependent_destroy",
                                   record: self.class.human_attribute_name(name).downcase.singularize))
          return false
        end
      end
    end
  end
end

module Exceptions
  class JavascriptError < StandardError
  end
end
