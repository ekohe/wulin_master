class <%= class_name.pluralize %>Controller < WulinMaster::ScreenController
  controller_for_screen <%= class_name %>Screen
  controller_for_grid :<%= underscored_name %>
  
  # You can add a callback when grid is render
  # 
  # ==== Args
  # * +grid+ - Current grid.
  # * +params+ - Parameters in the current action.
  # def before_render_grid(grid, params)
  #   codes........
  # end
  
end
