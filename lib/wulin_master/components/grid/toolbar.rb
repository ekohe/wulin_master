# frozen_string_literal: true

require 'wulin_master/components/grid/toolbar_item'

module WulinMaster
  class Toolbar
    @default_icons = {
      create: :add_box,
      add_detail: :add_box,
      show_all: :format_align_justify,
      json_view: :pageview,
      send_mail: :mail,
      edit: :mode_edit,
      delete: :delete,
      switch: :launch
    }

    class << self
      attr_reader :default_icons

      def add_default_icon(action, icon)
        @default_icons[action] = icon
      end
    end

    attr_reader :grid_name, :items

    def initialize(grid_name, actions = [])
      @grid_name = grid_name
      @items ||= []

      actions.each do |action|
        item_options = {
          id: "#{action[:name]}_action_on_#{grid_name}",
          class: ("#{action[:name]}_action " + action[:class].to_s),
          icon: (action[:icon] || Toolbar.default_icons[action[:name].to_sym]).to_s,
          manually_enable: action[:manually_enable]
        }
        item_options = action.merge(item_options)
        item_name = action[:title] || action[:name].capitalize

        @items << ToolbarItem.new(item_name, item_options)
      end
    end
  end
end
