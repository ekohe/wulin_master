# grid options

module WulinMaster
  module GridOptions
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        class << self
          attr_reader :options_pool
        end
      end
    end
    
    # --------------------- Class Methods ----------------------------
    module ClassMethods
      def initialize_options
        @options_pool ||= []
      end  

      def option(option)
        @options_pool << option
      end 
      
      def options(*args)
        args.each do |arg|
          option(arg)
        end
      end

      # helpers
      def cell_editable(value=true, options={})
        option({editable: value}.merge options)
      end

      def column_sortable(value=true, options={})
        option({sortable: value}.merge options)
      end

      def hide_header(value=true, options={})
        option({hide_header: value}.merge options)
      end
    end

    # ----------------------- Instance Methods ------------------------------
    def options
      self.class.options_pool
      .select {|option| option[:screens].nil? or (self.params["screen"] and option[:screens].include?(self.params["screen"].intern)) }
      .inject({}) {|h, e| h.merge(e)}
    end

    # helpers
    def cell_editable?
      options[:editabled] == true
    end

    def column_sortable?
      options[:sortable] == true
    end

    def hide_header?
      options[:hide_header] == true
    end

  end
end