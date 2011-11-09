module WulinMaster
  module GridStyling
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        class_attribute :_height, :styles, :_width, :_fill_window
      end
    end
    
    module ClassMethods
      
      # Set new grid height
      def height(new_height)
        self._height = new_height
        self.styles ||= []
        self.styles << "height: #{@height};"
        self._height
      end

      # Set new grid width
      def width(new_width)
        self._width = new_width
        self.styles ||= []
        self.styles << "width: #{@width};"
        self._width
      end

      # Set fill window mode
      def fill_window
        self._fill_window = true
        self.styles ||= []
        self.styles << "height: 100%; width: 100%; position: absolute; left:0; right:0;"
      end
      
      # Returns true if set to fill window. The template will just render the first grid of the screen.
      def fill_window?
        self._fill_window == true
      end
      
      # Set custom CSS
      def css(style)
        self.styles ||= []
        self.styles << style.to_s
      end
      
      # Return style to apply to the grid container
      def style
        self.styles.join(' ')
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