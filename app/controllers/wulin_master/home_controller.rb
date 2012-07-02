module WulinMaster
  class HomeController < ApplicationController  
    self.view_paths = [File.join(Rails.root, 'app', 'views'), File.join(File.dirname(__FILE__), '..', '..', 'views')]
    
    def change_password
      if defined?(WulinOAuth) 
        if request.post?
          response = HTTParty.post(WulinOAuth.configuration['change_password_uri'], :body => { :user => {
            :email => User.current_user.email,
            :current_password => params[:current_password], 
            :password => params[:password], 
            :password_confirmation => params[:password_confirmation]}}
          )
          render text: response
        else
          begin
            render 'change_password', layout: false
          rescue ActionView::MissingTemplate
            render '/change_password', layout: false
          end
        end
      else
        render text: "WulinOAuth is not install, Install it first!"
      end
    end

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
        title = options[:label] ||
                (title_or_screen_class.respond_to?(:title) ? title_or_screen_class.title : title_or_screen_class.to_s)
        path = options[:url] ||
               (title_or_screen_class.respond_to?(:path) ? title_or_screen_class.path : '/')
        if options[:authorized?]
          if options[:authorized?].kind_of?(Proc)
            is_authorized = (context && context.respond_to?(:current_user)) ? options[:authorized?].call(context.current_user) : options[:authorized?].call(nil)
            return unless is_authorized
          else
            return unless (is_authorized == true)
          end
        elsif title_or_screen_class.kind_of?(Class)
          screen_instance = title_or_screen_class.new(options, context) if title_or_screen_class.kind_of?(Class)
          path = screen_instance.path
          if screen_instance.respond_to?(:authorized?)
            is_authorized = (context && context.respond_to?(:current_user)) ? screen_instance.authorized?(context.current_user) : screen_instance.authorized?(nil)
            return unless is_authorized
          end
        end
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
      self.class.context = self
      self.class.menu_block.call(self) unless self.class.menu_block.nil?
      self.class.context = nil
      self.class.get_menu
    end
  end
end