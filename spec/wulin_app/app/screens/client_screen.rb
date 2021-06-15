# frozen_string_literal: true

class ClientScreen < WulinMaster::Screen
  title 'Clients'

  path '/clients'

  grid ClientGrid
end
