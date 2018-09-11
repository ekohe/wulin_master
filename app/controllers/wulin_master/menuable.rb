# frozen_string_literal: true

module WulinMaster
  module Menuable
    extend ActiveSupport::Concern

    # Generate menu
    def menu
      self.class.menu = Menu.new
      self.class.context = self
      self.class.menu_block&.call(self)
      self.class.context = nil
      self.class.prepare_menu
    end

    module ClassMethods
      attr_accessor :menu_block, :context
      attr_writer :menu

      # Menu definition
      def menu(&block)
        @menu_block = block
      end

      # Called within the block
      def submenu(title = nil)
        if block_given?
          @submenu = SubMenu.new(title)
          yield
          @menu << @submenu unless @submenu.empty?
          @submenu = nil
        end
        @submenu
      end

      def item(title_or_screen_class, options = {})
        return unless @menu

        screen_instance = title_or_screen_class.new(context) if title_or_screen_class.is_a?(Class)
        authorized_proc = options.delete(:authorized?)

        title = options[:label] ||
                (title_or_screen_class.respond_to?(:title) ? title_or_screen_class.title : title_or_screen_class.to_s)
        path = options[:url] ||
               (screen_instance.respond_to?(:path) ? screen_instance.path : '/')

        if authorized_proc
          if authorized_proc.is_a?(Proc)
            is_authorized = context&.respond_to?(:current_user) ? authorized_proc.call(context.current_user) : authorized_proc.call(nil)
            return unless is_authorized
          else
            return unless authorized_proc == true
          end
        elsif title_or_screen_class.is_a?(Class)
          if screen_instance.respond_to?(:authorized?)
            is_authorized = context&.respond_to?(:current_user) ? screen_instance.authorized?(context.current_user) : screen_instance.authorized?(nil)
            return unless is_authorized
          end
        end
        options[:screen_name] = screen_instance.try(:name)
        if @submenu
          @submenu << MenuEntry.new(title, path, options)
        else
          @menu << MenuEntry.new(title, path, options)
        end
      end

      def prepare_menu
        @menu
      end
    end
  end
end
