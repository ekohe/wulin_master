# frozen_string_literal: true

class PersonScreen < WulinMaster::Screen
  title 'People'

  path '/people'

  grid PersonGrid
end
