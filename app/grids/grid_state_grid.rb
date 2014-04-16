class GridStateGrid < WulinMaster::Grid
  model WulinMaster::GridState

  path '/wulin_master/grid_states'

  cell_editable false

  column :user_email, label: 'User'
  column :grid_name
  column :name

  action :delete
  action :filter
end
