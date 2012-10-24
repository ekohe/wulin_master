class GridStateGrid < WulinMaster::Grid
  model WulinMaster::GridState

  path '/wulin_master/grid_states'

  column :email, through: :user, label: 'User'
  column :grid_name
  column :name

  action :delete
  action :filter
end
