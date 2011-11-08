class <%= class_name.pluralize %>Controller < WulinMaster::ScreenController
  controller_for_screen <%= class_name %>Screen
  controller_for_grid <%= class_name %>Grid
end