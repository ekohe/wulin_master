# frozen_string_literal: true

module WulinMaster
  class AppBarMenu
    class_attribute :menus, default: []

    class << self
      def id
        name
      end

      def class_name
        ''
      end

      def data_option
        {}
      end

      def url
        '#'
      end

      def label; end

      # to add a menu
      def add_menu(menu)
        menus.push(menu)
        yield(menu) if block_given?
      end

      def inherited(subclass)
        subclass.menus = []
      end

      def orderd_menus
        menus.sort_by(&:order) # order alphabetically
      end

      def sub_menus?
        false
      end
    end
  end
end

class ActivityMenu < WulinMaster::AppBarMenu
  class << self
    def class_name
      'dropdown-trigger disabled'
    end

    def data_option
      { target: "#{id}-list" }
    end

    def order
      1
    end

    def icon
      :notifications
    end

    def sub_menus?
      true
    end
  end
end
