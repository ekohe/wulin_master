module WulinMaster
  module ComponentStyling
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        FILL_WINDOW_CSS = "height: 100%; width: 100%; position: absolute; left:0; right:0;"

        class << self
          attr_reader :styles_pool
        end
      end
    end
    
    module ClassMethods
      def initialize_styles
        @styles_pool = {}
      end  

      # Set new component height
      def height(new_height, options={})
        fill_window(false, options)
        height_str = "height: #{new_height};"

        add_style(height_str, options[:screen])
      end

      # Set new component width
      def width(new_width, options={})
        fill_window(false, options)
        width_str = "width: #{new_width};"

        add_style(width_str, options[:screen])
      end

      # Set fill window mode
      def fill_window(value=true, options={})
        value ? add_style(FILL_WINDOW_CSS, options[:screen]) : remove_style(FILL_WINDOW_CSS, options[:screen])
      end
      
      # Set custom CSS
      def css(style, options={})
        add_style(style.to_s, options[:screen])
      end

      # Add a style into component of different screens
      def add_style(style_str, screen)
        if screen
          @styles_pool[screen] ||= []
          @styles_pool[screen] << style_str unless @styles_pool[screen].include?(style_str)
        else
          @styles_pool[:_common] ||= []
          @styles_pool[:_common] << style_str unless @styles_pool[:_common].include?(style_str)
        end
      end

      # Remove a style from a component
      def remove_style(style_str, screen)
        if screen 
          @styles_pool[screen].delete(style_str) if @styles_pool[screen]
        elsif @styles_pool[:_common]
          @styles_pool[:_common].delete(style_str)
        end
      end
    end
    
    # ----------------------------- Instance Methods ------------------------------------

    # Return style to apply to the component container
    def style
      return "" if self.class.styles_pool.blank?

      common_style = self.class.styles_pool[:_common] || []
      common_style_without_fill_window = common_style - [FILL_WINDOW_CSS]
      if screen = self.params.try(:[], :screen)
        screen_style = self.class.styles_pool[screen] || []
        (screen_style.blank? ? common_style : (screen_style + common_style_without_fill_window)).uniq.join(" ")
      else
        common_style.join(" ")
      end
    end
    
    # Returns true if one component is set to fill window. The template will just render the previous components of the screen.
    def fill_window?
      style.include? FILL_WINDOW_CSS
    end
  end
end