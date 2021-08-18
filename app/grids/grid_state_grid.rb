# frozen_string_literal: true

class GridStateGrid < WulinMaster::Grid
  model WulinMaster::GridState

  path '/wulin_master/grid_states'

  cell_editable false

  column :email, label: 'User'
  column :grid_name
  column :state_value, editable: true, only: [:GridStatesScreen]
  column :name, label: 'View Name'
  column :current, label: 'Is Current View?', sortable: false, filterable: false

  action :make_default_grid, title: "Set as Initial", icon: :publish, toolbar_item: true
  action :filter_default_grid_states, toolbar_item: false

  action :delete
end
