module WulinMaster
  module GridDynamicEditForm
    extend ActiveSupport::Concern

    included do
      class_attribute :edit_column_group, instance_writer: false
      self.edit_column_group = {}
    end

    module ClassMethods
      # Define dynamic edit form
      #
      # Example:
      #
      #     edit_form :version1, :version2 do |form|
      #       form << :name
      #     end
      #
      #     edit_form :version2, class: 'version2_toolbar', icon: 'add' do |form|
      #       form << :code
      #     end
      #
      # It will define two edit form: version1, version2. form version1 has column [:name], form version2 has column [:name, :code]
      #
      # meanwhile two toolbars was defined: version1, version2.
      # the options <code>class: 'version2_toolbar', icon: 'add'</code> is same as +action+ method arguments.
      def edit_form(*args)
        action :dynamic_edit, visible: false

        options = {icon: 'edit'}.merge(args.extract_options!) # Set default icon
        options[:class] ? options[:class] << ' dynamic_toolbar' : options[:class] = 'dynamic_toolbar' # Set common class

        args.each do |group_key|
          options[:data] = {version: group_key} # Add version to the toolbar
          action(group_key, options)
          edit_column_group[group_key] = []
          yield edit_column_group[group_key]
        end
      end
    end

    def find_columns_by_version(version)
      edit_column_group.with_indifferent_access[version]
    end
  end
end
