module WulinMaster
  module Utilities
    extend self

    def get_grid_name(grid_class_name, screen_class_name)
      grid_name = grid_class_name.sub('Grid', '').underscore
      screen_name = get_screen_name(screen_class_name)
      screen_name == grid_name ? grid_name : "#{grid_name}_in_#{screen_name}"
    end

    def get_screen_name(screen_class_name)
      screen_class_name.sub(/Screen$/, "").underscore
    end
  end
end
