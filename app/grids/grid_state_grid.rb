# frozen_string_literal: true

class GridStateGrid < WulinMaster::Grid
  model WulinMaster::GridState

  path '/wulin_master/grid_states'

  cell_editable false

  column :email, label: 'User'
  column :grid_name
  column :name
  column :current, editable: false, formable: false, sortable: false, filterable: false

  action :delete
end
