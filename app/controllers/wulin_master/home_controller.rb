module WulinMaster
  class HomeController < ApplicationController

    def index
      dashboard if self.respond_to?(:dashboard)
      respond_to do |format|
        format.html do
          if request.xhr?
            begin
              render :template => 'homepage/dashboard', :layout => false
            rescue
              render :text => ''
            end
          else
            begin
              render 'index'
            rescue ActionView::MissingTemplate
              render '/home'
            end
          end
        end
      end
    end
    
    class << self
      attr_accessor :menu_block, :menu, :context

      # Menu definition
      def menu(&block)
        @menu_block = block
      end

      # Called within the block
      def submenu(title=nil)
        if block_given?
          @submenu = SubMenu.new(title)
          yield
          @menu << @submenu if @submenu.size > 0
          @submenu = nil
        end 
        return @submenu   
      end

      def item(title_or_screen_class, options={})
        return unless @menu
        screen_instance = title_or_screen_class.new(options, context) if title_or_screen_class.kind_of?(Class)

        title = options[:label] ||
                (title_or_screen_class.respond_to?(:title) ? title_or_screen_class.title : title_or_screen_class.to_s)
        path = options[:url] ||
               (screen_instance.respond_to?(:path) ? screen_instance.path : '/')

        if options[:authorized?]
          if options[:authorized?].kind_of?(Proc)
            is_authorized = (context && context.respond_to?(:current_user)) ? options[:authorized?].call(context.current_user) : options[:authorized?].call(nil)
            return unless is_authorized
          else
            return unless (is_authorized == true)
          end
        elsif title_or_screen_class.kind_of?(Class)
          if screen_instance.respond_to?(:authorized?)
            is_authorized = (context && context.respond_to?(:current_user)) ? screen_instance.authorized?(context.current_user) : screen_instance.authorized?(nil)
            return unless is_authorized
          end
        end
        if @submenu
          @submenu << MenuEntry.new(title, path, options)
        else
          @menu << MenuEntry.new(title, path, options)
        end
      end
      
      def get_menu
        @menu
      end
    end

    # Generate menu
    def menu
      self.class.menu = Menu.new
      self.class.context = self
      self.class.menu_block.call(self) unless self.class.menu_block.nil?
      self.class.context = nil
      self.class.get_menu
    end
  end
end