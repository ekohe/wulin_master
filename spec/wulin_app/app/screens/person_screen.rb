# frozen_string_literal: true

class PersonScreen < WulinMaster::Screen
  title 'People'

  path '/people'

  grid PersonGrid, width: '50%'
  grid PostGrid, width: '50%', master_grid: 'PersonGrid', eager_loading: false
end
