require File.join(File.dirname(__FILE__), 'toolbar_item')

module WulinMaster
  class Toolbar < Array
    def initialize
      self.class.default_items.each {|item| self.unshift(item) }
    end
    
    # Renders the toolbar as HTML snippet
    def render
      items = self.collect do |item|
        item.render
      end.join("").html_safe
      "<div id=\"toolbar\">#{items}</div>".html_safe
    end
    
    # Default toolbar
    @@default_items = [
      ToolbarItem.new("Add",    :class => 'create_button', :icon => 'create'),
      ToolbarItem.new("Delete", :class => 'delete_button', :icon => 'delete_trash'),
      ToolbarItem.new("Filter", :class => 'filter_toggle', :icon => 'search'),
      ToolbarItem.new("Update", :class => 'batch_update_button', :icon => 'batch_update')
    ]
    
    # Add to default toolbar
    def self.add_to_default_toolbar(item, options={})
      if item.kind_of?(ToolbarItem)
        @@default_items << item
      elsif item.kind_of?(String)
        @@default_items << ToolbarItem.new(item, options)
      else
        raise "Invalid type #{item.class}"
      end
    end
    
    # Returns the default toolbar items
    def self.default_items
      @@default_items
    end
  end
end