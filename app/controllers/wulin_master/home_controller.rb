module WulinMaster
  class HomeController < ApplicationController  
    @@menu = nil
    @@submenu = nil

    self.view_paths = [File.join(Rails.root, 'app', 'views'), File.join(File.dirname(__FILE__), '..', '..', 'views')]

    def index
      respond_to do |format|
        format.html do
          begin
            render 'index'
          rescue ActionView::MissingTemplate
            render '/home'
          end
        end
      end
    end

    # Menu definition
    def self.menu
      if block_given?
        @@menu = Menu.new
        yield
      end
      return @@menu
    end

    def self.submenu(title=nil)
      if block_given?
        @@submenu = SubMenu.new(title)
        yield
        @@menu << @@submenu
      end 
      return @@submenu   
    end
    
    def self.menu=(menu)
      @@menu = menu
    end
    
    def self.submenu=(submenu)
      @@submenu = submenu
    end
    
    def menu
      self.class.menu
    end

    def self.item(title_or_screen_class, path=nil)
      return unless @@menu
      title = title_or_screen_class.respond_to?(:title) ? title_or_screen_class.title : title_or_screen_class
      path = path.to_s.presence || (title_or_screen_class.respond_to?(:path) ? title_or_screen_class.path : '/')
      if @@submenu
        @@submenu << MenuEntry.new(title, path)
      else
        @@menu << MenuEntry.new(title, path)
      end
    end
  end
end