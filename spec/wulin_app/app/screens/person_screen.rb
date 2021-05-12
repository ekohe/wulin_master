# frozen_string_literal: true

class PersonScreen < WulinMaster::Screen
  title 'People'

  path '/people'

  grid PersonGrid, width: '30%'
  grid PostGrid, width: '30%', master_grid: 'PersonGrid', eager_loading: false
  panel PostFormPanel, width: '40%'
end
