# frozen_string_literal: true

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
        options_pool << option unless options_pool.include?(option)
      end

      def options(*args)
        args.each do |arg|
          option(arg)
        end
      end

      # helpers
      def cell_editable(value = true, options = {})
        option({editable: value}.merge(options))
      end

      def checkbox(value = false, options = {})
        option({checkbox:  {enable: value}.merge(options)})
      end

      def column_sortable(value = true, options = {})
        option({sortable: value}.merge(options))
      end

      def hide_header(value = true, options = {})
        option({hide_header: value}.merge(options))
      end

      def eager_loading(value = true, options = {})
        option({eagerLoading: value}.merge(options))
        return unless value == false
        screens = options[:only] || [options["screen"].try(:intern)].compact
        behavior :disable_toolbar_initially, only: screens
        behavior :disable_sorting_initially, only: screens
        behavior :enable_toolbar_after_loading, only: screens
        behavior :enable_sorting_after_loading, only: screens
      end

      def multi_select(value = true, options = {})
        option({multiSelect: value}.merge(options))
      end

      def color_theme(value = 'blue-grey', options = {})
        option({colorTheme: value}.merge(options))
      end

      def selection_color(value = 'blue-grey', options = {})
        option({selectionColor: value}.merge(options))
      end

      def background_color(value = 'blue-grey', options = {})
        option({bgColor: value}.merge(options))
      end

      def estimate_count(value = {threshold: 10000}, options = {})
        option({estCount: value}.merge(options))
      end

      def default_sorting_state(value = {id: 'ASC'}, options = {})
        option({defaultSortingState: value}.merge(options))
      end

      def row_height(value = 26, options = {})
        option({rowHeight: value}.merge(options))
      end

      def row_detail(options = {})
        options = {
          panelRows: 4,
          useRowClick: false,
          showTriggerColumn: true,
          cssClass: 'detailView-toggle',
          loadingTemplate: 'Loading...',
          postTemplate: :default
        }.merge(options)
        option(rowDetail: options)
      end
    end

    def options
      add_options_user_read_only_permission
      # make sure the common option comes first so that the specific option for a screen can override it when merging
      the_options = self.class.options_pool.sort_by { |s| s[:only] || s[:except] || [] }.
                    select { |option| valid_option?(option) }.
                    inject({}) { |h, e| h.merge(e.reject { |k, _v| (k == :only) || (k == :except) }) }
      setup_cell_editable_for_current_user(the_options)
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
      (option[:only].blank? && option[:except].blank?) ||
        (option[:only].present? && params[:screen].present? && option[:only].include?(params[:screen].intern)) ||
        (option[:except].present? && params[:screen].present? && option[:except].exclude?(params[:screen].intern))
    end

    def setup_cell_editable_for_current_user(option)
      return option if params[:screen].blank?
      option[:editable] = screen.authorize_create? if option[:editable].is_a?(TrueClass)
      option
    end

    def add_options_user_read_only_permission
      return unless current_user
      key = [current_user.id, :read_only_permission].join(":")
      columns_pool.each { |column_pool| column_pool.options[key] = !screen.authorize_create? if column_pool.options.key?('editable') }
    end
  end
end
