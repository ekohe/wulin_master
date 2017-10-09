# toolbar items come from actions

module WulinMaster
  module GridActions
    extend ActiveSupport::Concern

    included do
      ORIGINAL_ACTIONS = %w[create delete edit]
      SENSITIVE_ACTIONS = %w[create delete edit hotkey_create hotkey_delete]

      class << self
        attr_reader :actions_pool
        def actions_pool
          @actions_pool ||= []
        end
      end
    end

    module ClassMethods
      # action DSL, add an action to the actions_pool
      def action(a_name, options = {})
        new_action = {name: a_name}.merge(options)
        actions_pool << new_action
        add_hotkey_action(a_name, options)
      end

      def add_actions(*args)
        args.each do |arg|
          action(arg)
        end
      end

      def remove_actions(*args)
        args.each do |arg|
          actions_pool.delete_if { |action| action[:name] == arg.to_s }
        end
      end

      def load_default_actions(options = {})
        ORIGINAL_ACTIONS.each do |oa|
          action(oa, options)
        end
        # special actions needed to be load as default
        # action :hotkey_add, visible: false
        # action :hotkey_delete, visible: false
      end

      # interface open to other plugins
      def add_default_action(action)
        ORIGINAL_ACTIONS << action
      end

      def add_hotkey_action(action_name, action_options)
        action_name = action_name.to_s
        if (action_name == 'create') && !actions_pool.find { |x| x[:name].to_s == 'hotkey_create' }
          actions_pool << {name: :hotkey_create, visible: false}.merge(action_options)
        elsif (action_name == 'delete') && !actions_pool.find { |x| x[:name].to_s == 'hotkey_delete' }
          actions_pool << {name: :hotkey_delete, visible: false}.merge(action_options)
        end
      end
    end

    # the actions of a grid instance, filtered by screen param from class's actions_pool
    def actions
      return self.class.actions_pool if params["screen"].blank?
      self.class.actions_pool.select { |action| valid_action?(action) }.uniq { |action| action[:name] }
    end

    # the actions on the toolbar
    def toolbar_actions
      actions.reject { |action| action[:toolbar_item] == false || action[:visible] == false }
    end

    # the actions on the grid header (not on the toolbar)
    def header_actions
      actions.select { |action| action[:toolbar_item] == false }
    end

    def action_configs
      actions.map { |a| a.reject { |k, _v| (k == :only) || (k == :except) } }
    end

    def action_names
      actions.map { |a| a[:name].to_s }
    end

    private

    def valid_action?(action)
      valid_action_by_screen_configuration?(action) &&
        valid_by_screen_authorize_create?(action) &&
        valid_by_action_authorized?(action)
    end

    # 1. check if this action can be displayed in the screen due to :only or :except configuration
    def valid_action_by_screen_configuration?(action)
      (action[:only].blank? && action[:except].blank?) ||
        (action[:only].present? && params[:screen].present? && action[:only].include?(params[:screen].intern)) ||
        (action[:except].present? && params[:screen].present? && action[:except].exclude?(params[:screen].intern))
    end

    # 2. check if this screen creation authorized for current user if action is cud
    def valid_by_screen_authorize_create?(action)
      return true unless current_user
      self.class::SENSITIVE_ACTIONS.exclude?(action[:name].to_s) || screen.authorize_create?
    end

    # 3. check if this action authorized for current user
    def valid_by_action_authorized?(action)
      return true unless action[:authorized?] && current_user
      authorized_proc = action.delete(:authorized?)
      if authorized_proc.is_a?(Proc)
        return authorized_proc.call(current_user)
      else
        return authorized_proc == true
      end
    end
  end
end
