# frozen_string_literal: true

module WulinMaster
  class AppBarMenu
    # menus:
    # { logout: { title: 'Logout', icon: 'lock', url: '/logout' } }
    class_attribute :menus, default: {}

    class << self
      # to add a menu
      def add_menu(name, options)
        menus[name.to_sym] = { title: name.to_s.titleize, **options }
      end

      # mainly to unbind the default menus
      def remove_menu(name)
        menus.delete(name.to_sym)
      end
    end
  end
end
