module WulinMaster
  module GridColumns
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        class << self
          attr_accessor :columns
        end
      end
    end
    
    module ClassMethods
      # Private - executed when class is subclassed
      def initialize_columns
        self.columns ||= [Column.new(:id, self, {:visible => false, :editable => false, :sortable => true})]
      end
      
      # Add a column
      def column(name, options={})
        self.columns += [Column.new(name, self, options)]
      end
      
      # Remove columns for exactly screens
      def remove_columns(r_columns, scope={})
        return unless scope[:screen].present?
        
        r_columns = r_columns.map(&:to_s)
        self.columns.each do |column|
          if r_columns.include? column.name.to_s
            column.options[:except] = scope[:screen]
          end
        end
      end
    end
    
    # Instance Methods

    # Returns columns
    def columns
      screen_name = params[:screen]
      columns_pool = self.class.columns.dup
      
      columns_pool.select do |column|
        valid_column?(column, screen_name)
      end
    end
    
    
    private
    
    def valid_column?(column, screen_name)
      screen_name = screen_name.to_s
      (column.options[:only].blank? and column.options[:except].blank?) ||
      (column.options[:only].present? and column.options[:only].map(&:to_s).include?(screen_name)) ||
      (column.options[:except].present? and column.options[:except].map(&:to_s).exclude?(screen_name))
    end
    
  end
end