# frozen_string_literal: true

class AnotherPersonScreen < WulinMaster::Screen
  title "People"

  path "/people"

  panel PostFormPanel, height: "40%"
  grid PersonGrid, height: "30%"
  grid PostGrid, height: "30%", master_grid: "PersonGrid", eager_loading: false
end
