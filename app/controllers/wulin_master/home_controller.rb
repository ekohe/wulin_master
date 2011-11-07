module WulinMaster
  class HomeController < ApplicationController  
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
    
    class << self
      attr_accessor :menu_block, :menu

      # Menu definition
      def menu(&block)
        @menu_block = block
      end

      # Called within the block
      def submenu(title=nil)
        if block_given?
          @submenu = SubMenu.new(title)
          yield
          @menu << @submenu
          @submenu = nil
        end 
        return @submenu   
      end

      def item(title_or_screen_class, path=nil)
        return unless @menu
        title = title_or_screen_class.respond_to?(:title) ? title_or_screen_class.title : title_or_screen_class
        path = path.to_s.presence || (title_or_screen_class.respond_to?(:path) ? title_or_screen_class.path : '/')
        if @submenu
          @submenu << MenuEntry.new(title, path)
        else
          @menu << MenuEntry.new(title, path)
        end
      end
      
      def get_menu
        @menu
      end
    end

    # Generate menu
    def menu
      self.class.menu = Menu.new
      self.class.menu_block.call(self) unless self.class.menu_block.nil?
      self.class.get_menu
    end
  end
end