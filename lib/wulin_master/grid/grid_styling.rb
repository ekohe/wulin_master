module WulinMaster
  module GridStyling
    extend ActiveSupport::Concern
    module ClassMethods
      
      # Set new grid height
      def height(new_height)
        @height = new_height
        @styles ||= []
        @styles << "height: #{@height};"
        @height
      end

      # Set new grid width
      def width(new_width)
        @width = new_width
        @styles ||= []
        @styles << "width: #{@width};"
        @width
      end

      # Set fill window mode
      def fill_window
        @fill_window = true
        @styles ||= []
        @styles << "height: 100%; width: 100%; position: absolute; left:0; right:0;"
      end
      
      # Returns true if set to fill window. The template will just render the first grid of the screen.
      def fill_window?
        @fill_window == true
      end
      
      # Set custom CSS
      def css(style)
        @styles ||= []
        @styles << style.to_s
      end
      
      # Return style to apply to the grid container
      def style
        @styles.join(' ')
      end
    end
    
    module InstanceMethods
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
end