# frozen_string_literal: true

module WulinMaster
  class AppBarMenu
    class_attribute :menus, default: []

    class << self
      def label; end

      # to add a menu
      def add_menu(menu)
        menus.push(menu)
      end

      def inherited(subclass)
        subclass.menus = []
      end

      def orderd_menus
        menus.sort_by(&:order) # order alphabetically
      end
    end
  end
end

class ActivityMenu < WulinMaster::AppBarMenu
  class << self
    def order
      1
    end

    def icon
      :notifications
    end
  end
end
