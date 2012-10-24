class GridStatesScreen < WulinMaster::Screen
  title 'Grid States Management'

  path '/wulin_master/grid_states'

  grid UserGrid, width: '45%', height: '100%', css: 'float: right', multi_select: true    # should be loaded first, to cache the all users
  grid GridStateGrid, width: '45%', height: '100%', title: 'Grid States'
  panel GridStateUserPanel, width: '10%', height: '100%'
end