module WulinMaster
  module GridToolbar
    extend ActiveSupport::Concern
    module ClassMethods
      def initialize_toolbar
        @toolbar = Toolbar.new
      end

      attr_accessor :toolbar

      # Add an item to the toolbar
      def add_to_toolbar(item, options={})
        if item.class == ToolbarItem
          @toolbar << item
        elsif item.class == String
          @toolbar << ToolbarItem.new(item, options)
        end
      end
    end

    module InstanceMethods
      # Returns the toolbar
      def toolbar
        self.class.toolbar
      end
    end
  end
end