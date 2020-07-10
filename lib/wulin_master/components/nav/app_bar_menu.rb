# frozen_string_literal: true

module WulinMaster
  module AppBarMenu
    def self.menus
      @menus ||= MainMenu.new(:app_bar_menu)
    end

    def self.sorted_main_menus
      menus.sorted_by_order_asc
    end
  end

  class MainMenu
    attr_accessor :menus, :name, :options

    def initialize(name, options = {})
      @name = name
      @options = options
      @menus = []
    end

    def add_menu(name, options = {})
      menu = find_or_initialize_menu(name, options)
      menus.push(menu)
      yield(menu) if block_given?
    end

    def sorted
      menus.sort_by { |menu| menu.options[:order] }
    end

    def find(name)
      menu = @menus.detect { |x| x.name == name }
      yield(menu) if block_given?
      menu
    end

    def sorted_by_order_asc
      menus.sort_by { |menu| menu.options[:order] }
    end

    private

    def find_or_initialize_menu(name, options)
      @menus.detect { |x| x.name == name } || MainMenu.new(name, options)
    end
  end
end
