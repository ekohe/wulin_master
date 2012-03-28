module WulinMaster
  module GridToolbar
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        class_attribute :toolbar
      end
    end
    
    module ClassMethods
      def initialize_toolbar
        self.toolbar ||= Toolbar.new
      end

      # ! This method is wrong, can be deleted
      # Add an item to the toolbar
      def add_to_toolbar(item, options={})
        if item.class == ToolbarItem
          self.toolbar +=[item]
        elsif item.class == String
          self.toolbar += [ToolbarItem.new(item, options)]
        end
      end
    end

    # Instance methods

    # Returns the toolbar
    def toolbar
      self.class.toolbar
    end
  end
end