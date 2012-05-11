module WulinMaster
  module GridToolbar
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        # class_attribute :toolbar
        class <<self
          attr_accessor :toolbar
        end
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
          self.toolbar << item
        elsif item.class == String
          self.toolbar << ToolbarItem.new(item, options)
        end
      end
    end

    # Instance methods

    # Returns the toolbar
    def toolbar
      if self.controller.respond_to?(:current_user) and !self.controller.screen.authorize_create?(self.controller.current_user)
        self.class.toolbar.dup.delete_if {|item| %w(add edit delete).include?(item.title.downcase)}
      else
        self.class.toolbar
      end
    end
    
  end
end