# grid options

module WulinMaster
  module GridOptions
    extend ActiveSupport::Concern
    
    included do
      class << self
        attr_accessor :options_pool
        def options_pool
          @options_pool ||= []
        end
      end
    end

    module ClassMethods
      def option(option)
        # turn option["screen"] to option[:only]
        option[:only] = [option[:screen].intern] if option[:screen]
        self.options_pool << option unless self.options_pool.include?(option)
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

    def options
      # make sure the common option comes first so that the specific option for a screen can override it when merging
      the_options = self.class.options_pool.sort_by{|s| s[:only] || s[:except] || [] }
      .select {|option| valid_option?(option)}
      .inject({}) {|h, e| h.merge(e.reject{|k,v| k == :only or k == :except})}
      set_cell_editable_for_current_user(the_options)
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

    def valid_option?(option)
      (option[:only].blank? and option[:except].blank?) ||
      (option[:only].present? and params[:screen].present? and option[:only].include?(params[:screen].intern)) ||
      (option[:except].present? and params[:screen].present? and option[:except].exclude?(params[:screen].intern))
    end

    def set_cell_editable_for_current_user(option)
      return option if params[:screen].blank?
      option[:editable] = screen.authorize_create? if option[:editable].is_a?(TrueClass)
      option
    end

  end
end