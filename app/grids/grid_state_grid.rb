# frozen_string_literal: true

class GridStateGrid < WulinMaster::Grid
  model WulinMaster::GridState

  path '/wulin_master/grid_states'

  cell_editable false

  column :email, label: 'User'
  column :grid_name
  column :name
  column :state_value, editable: true, only: [:GridStatesScreen]
  column :current, editable: false, formable: false, sortable: false, filterable: false

  action :make_default_grid, title: "Make default", icon: :publish, toolbar_item: true
  action :filter_default_grid_states, toolbar_item: false

  action :delete
end
