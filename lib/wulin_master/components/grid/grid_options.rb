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
        option[:only] = [option[:screen].intern] if option[:screen]
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

      def multi_select(value=true, options={})
        option({multiSelect: value}.merge options)
      end
    end

    # ----------------------- Instance Methods ------------------------------
    def options(current_user)
      # make sure the common option comes first so that the specific option for a screen can override it when merging
      the_options = self.class.options_pool.sort_by{|s| s[:only] || s[:except] || [] }
      .select {|option| valid_option?(option, self.params["screen"], current_user)}
      .inject({}) {|h, e| h.merge(e.reject{|k,v| k == :only or k == :except})}
      set_cell_editable_for_current_user(the_options, self.params["screen"], current_user)
    end

    # helpers
    def cell_editable?(current_user)
      options(current_user)[:editable] == true
    end

    def column_sortable?(current_user)
      options(current_user)[:sortable] == true
    end

    def hide_header?(current_user)
      options(current_user)[:hide_header] == true
    end

    private

    def valid_option?(option, screen_name, current_user)
      verify_screen_configuration(option, screen_name)
    end

    def verify_screen_configuration(option, screen_name)
      (option[:only].blank? and option[:except].blank?) ||
      (option[:only].present? and screen_name and option[:only].include?(screen_name.intern)) ||
      (option[:except].present? and screen_name and option[:except].exclude?(screen_name.intern))
    end

    def set_cell_editable_for_current_user(option, screen_name, current_user)
      screen = screen_name.safe_constantize.try(:new)
      option[:editable] = screen.authorize_create?(current_user) if option[:editable].is_a?(TrueClass)
      option
    end

  end
end