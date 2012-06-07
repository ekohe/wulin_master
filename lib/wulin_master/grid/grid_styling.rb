module WulinMaster
  module GridStyling
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        FILL_WINDOW_CSS = "height: 100%; width: 100%; position: absolute; left:0; right:0;"

        class << self
          attr_reader :_height, :_width, :_styles, :_fill_window
        end
      end
    end
    
    module ClassMethods
      # Set new grid height
      def height(new_height)
        fill_window false
        @_height = new_height
        @_styles << "height: #{@_height};"
      end

      # Set new grid width
      def width(new_width)
        fill_window false
        @_width = new_width
        @_styles << "width: #{@_width};"
      end

      # Set fill window mode
      def fill_window(value=true)
        @_fill_window = value
        @_styles ||= []
        value ? (@_styles << FILL_WINDOW_CSS unless @_styles.include?(FILL_WINDOW_CSS)) : @_styles.delete(FILL_WINDOW_CSS)
      end
      
      # Returns true if set to fill window. The template will just render the first grid of the screen.
      def fill_window?
        @_fill_window == true
      end
      
      # Set custom CSS
      def css(style)
        @_styles ||= []
        @_styles << style.to_s
      end
      
      # Return style to apply to the grid container
      def style
        @_styles.join(' ')
      end
    end
    
    # ----------------------------- Instance Methods ------------------------------------

    # Return style to apply to the grid container
    def style
      self.class.style
    end
    
    # Returns true if set to fill window. The template will just render the first grid of the screen.
    def fill_window?
      self.class.fill_window?
    end
  end
end