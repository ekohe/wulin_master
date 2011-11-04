module WulinMaster
  module GridColumns
    extend ActiveSupport::Concern
    module ClassMethods
      # Private - executed when class is subclassed
      def initialize_columns
        @columns = []
        @columns << Column.new(:id, self, {:visible => false, :editable => false, :sortable => true})
      end
      
      # Add a column
      def column(name, options={})
        @columns << Column.new(name, self, options)
      end

      # Returns columns
      def columns
        @columns
      end
    end
    
    module InstanceMethods
      # Returns columns
      def columns
        self.class.columns.clone
      end
    end
  end
end