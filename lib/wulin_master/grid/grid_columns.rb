module WulinMaster
  module GridColumns
    extend ActiveSupport::Concern
    module ClassMethods
      # Private - executed when class is subclassed
      def initialize_columns
        @_columns = []
        @_columns << Column.new(:id, self, {:visible => false, :editable => false, :sortable => true})
      end
      
      # Add a column
      def column(name, options={})
        @_columns << Column.new(name, self, options)
      end

      # Returns columns
      def columns
        @_columns
      end
    end
    
    module InstanceMethods
      # Returns columns
      def columns
        self.class.columns
      end
    end
  end
end