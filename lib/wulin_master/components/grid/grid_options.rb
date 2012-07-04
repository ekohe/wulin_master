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
        # turn option["screen"] to option[:only]
        option[:only] = [option["screen"].intern] if option["screen"]
        # simplify options by removing useless options
        ["action", "controller", "screen"].each {|o| option.delete(o)}

        @options_pool << option unless @options_pool.include?(option)
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

      def eager_loading(value=true, options={})
        option({eagerLoading: value}.merge options)
        if value == false
          screens = options[:only] || [options["screen"].try(:intern)].compact
          behavior :disable_toolbar_initially, only: screens
          behavior :disable_sorting_initially, only: screens
          behavior :enable_toolbar_after_loading, only: screens
          behavior :enable_sorting_after_loading, only: screens
        end
      end
    end

    # ----------------------- Instance Methods ------------------------------
    def options
      self.class.options_pool
      .select {|option| valid_option?(option, self.params["screen"])}
      .inject({}) {|h, e| h.merge(e.reject{|k,v| k == :only or k == :except})}
    end

    # helpers
    def cell_editable?
      options[:editable] == true
    end

    def column_sortable?
      options[:sortable] == true
    end

    def hide_header?
      options[:hide_header] == true
    end

    private

    def valid_option?(option, screen_name)
      (option[:only].blank? and option[:except].blank?) ||
      (option[:only].present? and screen_name and option[:only].include?(screen_name.intern)) ||
      (option[:except].present? and screen_name and option[:except].exclude?(screen_name.intern))
    end

  end
end