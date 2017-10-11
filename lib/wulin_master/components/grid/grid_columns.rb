# frozen_string_literal: true

module WulinMaster
  module GridColumns
    extend ActiveSupport::Concern

    included do
      class_attribute :columns_pool
    end

    module ClassMethods
      # Private - executed when class is subclassed
      def initialize_columns
        self.columns_pool ||= [Column.new(:id, self, visible: false, editable: false, sortable: true)]
      end

      # Add a column
      def column(name, options = {})
        self.columns_pool += [Column.new(name, self, options)]
      end

      # Remove columns for exactly screens
      def remove_columns(r_columns, scope = {})
        return if scope[:screen].blank?

        r_columns = r_columns.map(&:to_s)
        self.columns_pool.each do |column|
          if r_columns.include? column.name.to_s
            column.options[:except] = scope[:screen]
          end
        end
      end

      # For the old caller, in some old code, there some call like: +grid_class.columns+
      def columns
        self.columns_pool
      end
    end

    # Returns columns
    def columns
      screen_name = params[:screen]
      return self.class.columns_pool if screen_name.blank?

      all_columns = self.class.columns_pool.dup

      all_columns.select do |column|
        column.valid_in_screen(screen_name)
      end
    end
  end
end
