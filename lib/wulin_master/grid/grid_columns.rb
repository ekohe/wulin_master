module WulinMaster
  module GridColumns
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        class_attribute :columns
      end
    end
    
    module ClassMethods
      # Private - executed when class is subclassed
      def initialize_columns
        if self.columns.nil?
          self.columns = [Column.new(:id, self, {:visible => false, :editable => false, :sortable => true})]
        end
      end
      
      # Add a column
      def column(name, options={})
        self.columns += [Column.new(name, self, options)]
      end
    end
    
    # Instance Methods

    # Returns columns
    def columns
      self.class.columns
    end
  end
end