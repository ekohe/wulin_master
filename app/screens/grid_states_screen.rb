begin
  require 'user_grid'
rescue LoadError
end

class GridStatesScreen < WulinMaster::Screen
  title 'Grid States Management'

  path '/wulin_master/grid_states'

  if defined?(UserGrid)
    # should be loaded first, to cache the all users
    grid UserGrid, width: '45%', height: '100%', css: 'float: right', multi_select: true
    grid GridStateGrid, width: '45%', height: '100%', title: 'Grid States'
    panel GridStateUserPanel, width: '10%', height: '100%'
  else
    grid GridStateGrid, width: '100%', height: '100%', title: 'Grid States'
  end
end