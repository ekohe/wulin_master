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
        self.columns ||= []
        self.columns += [Column.new(:id, self, {:visible => false, :editable => false, :sortable => true})]
      end
      
      # Add a column
      def column(name, options={})
        self.columns += [Column.new(name, self, options)]
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