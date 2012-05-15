require File.join(File.dirname(__FILE__), 'toolbar_item')

module WulinMaster
  class Toolbar #< Array
    attr_reader :grid_name, :items

    def initialize(grid_name, actions=[])
      #self.class.default_items.each {|item| self.unshift(item) }
      @grid_name = grid_name
      @items ||= []
      actions.each do |action|
        @items << ToolbarItem.new((action[:title] || action[:name]).capitalize, :class => "#{action[:name]}_action", :icon => "#{action[:icon] || action[:name]}")
      end
    end
    
    # Renders the toolbar as HTML snippet
    def render
      e = @items.collect do |item|
        item.render
      end.join("").html_safe
      "<div class=\"toolbar\" data-grid=#{@grid_name}>#{e}</div>".html_safe
    end
    
    # # Default toolbar, to be deprecated
    # @@default_items = [
    #   ToolbarItem.new("Add",    :class => 'create_button', :icon => 'create'),
    #   ToolbarItem.new("Edit", :class => 'batch_update_button', :icon => 'batch_update'),
    #   ToolbarItem.new("Delete", :class => 'delete_button', :icon => 'delete_trash'),
    #   ToolbarItem.new("Filter", :class => 'filter_toggle', :icon => 'search')
    # ]
    
    # # Add to default toolbar
    # def self.add_to_default_toolbar(item, options={})
    #   if item.kind_of?(ToolbarItem)
    #     @@default_items << item
    #   elsif item.kind_of?(String)
    #     @@default_items << ToolbarItem.new(item, options)
    #   else
    #     raise "Invalid type #{item.class}"
    #   end
    # end

    # # Add new toolbar_item to start
    # def add_toolbar_item(item_title, options)
    #   self.push(ToolbarItem.new(item_title, options))
    # end

    # # Add new toolbar_item to end
    # def append_toolbar_item(item_title, options)
    #   self.unshift(ToolbarItem.new(item_title, options))
    # end
    
    # # Returns the default toolbar items
    # def self.default_items
    #   @@default_items
    # end
  end
end