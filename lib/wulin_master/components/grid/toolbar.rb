require 'wulin_master/components/grid/toolbar_item'

module WulinMaster
  class Toolbar #< Array
    attr_reader :grid_name, :items

    def initialize(grid_name, actions=[])
      #self.class.default_items.each {|item| self.unshift(item) }
      @grid_name = grid_name
      @items ||= []

      uids = {}

      actions.each do |action|
        uids[action[:name]] ||= 0

        item_options = {
            :id => "#{action[:name]}_action_on_#{grid_name}",
            :class => ("#{action[:name]}_action #{action[:name]}_action_on_#{grid_name}_#{uids[action[:name]]}" << action[:class].to_s),
            :icon => "#{action[:icon] || action[:name]}",
            :manually_enable => action[:manually_enable]
        }

        uids[action[:name]]+=1

        item_options = action.merge(item_options)
        item_options.delete(:authorized?)
        item_name = action[:title] || action[:name].capitalize

        @items << ToolbarItem.new(item_name, item_options)
      end
    end
  end
end