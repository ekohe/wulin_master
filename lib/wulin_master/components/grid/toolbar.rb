# frozen_string_literal: true

require 'wulin_master/components/grid/toolbar_item'

module WulinMaster
  class Toolbar
    attr_reader :grid_name, :items

    # TODO: This should be extendable through an API
    #  ie: wulin_audit/wulin_excel should be able to set the icon for the audit/excel action
    DEFAULT_ICONS = {
      create: 'add_box',
      add_detail: 'add_box',
      export: 'file_download',
      show_all: 'format_align_justify',
      json_view: 'pageview',
      send_mail: 'mail',
      edit: 'mode_edit',
      delete: 'delete',
      switch: 'launch',
      audit: 'restore',
      excel: 'file_download'
    }.freeze

    def initialize(grid_name, actions = [])
      @grid_name = grid_name
      @items ||= []

      actions.each do |action|
        item_options = {
          id: "#{action[:name]}_action_on_#{grid_name}",
          class: ("#{action[:name]}_action " + action[:class].to_s),
          icon: (action[:icon] || DEFAULT_ICONS[action[:name].to_sym]).to_s,
          manually_enable: action[:manually_enable]
        }
        item_options = action.merge(item_options)
        item_name = action[:title] || action[:name].capitalize

        @items << ToolbarItem.new(item_name, item_options)
      end
    end
  end
end
