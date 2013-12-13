require 'wulin_master/components/grid/toolbar_item'

module WulinMaster
  class Toolbar #< Array
    attr_reader :grid_name, :items

    def initialize(grid_name, actions=[])
      #self.class.default_items.each {|item| self.unshift(item) }
      @grid_name = grid_name
      @items ||= []

      actions.each do |action|
        item_options = {
            :id => "#{action[:name]}_action_on_#{grid_name}",
            :class => ("#{action[:name]}_action " << action[:class].to_s),
            :icon => "#{action[:icon] || action[:name]}",
            :manually_enable => action[:manually_enable]
        }
        item_options = action.merge(item_options)
        item_options.delete(:authorized?)
        # item_name = action[:title] || action[:name].capitalize
        item_name = action[:title] || I18n.t("wulin_master.button.#{action[:name]}")

        @items << ToolbarItem.new(item_name, item_options)
      end
    end
  end
end
