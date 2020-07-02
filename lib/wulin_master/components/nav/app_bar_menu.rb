# frozen_string_literal: true

module WulinMaster
  module AppBarMenu
    def self.menus
      @menus ||= MainMenu.new(:app_bar_menu)
    end

    def self.sorted_main_menus
      menus.menus.sort_by { |menu| menu.options[:order] }
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

    def find_or_initialize_menu(name, options)
      @menus.detect { |x| x.name == name } || MainMenu.new(name, options)
    end

    def sorted
      menus.sort_by { |menu| menu.options[:order] }
    end
  end
end
