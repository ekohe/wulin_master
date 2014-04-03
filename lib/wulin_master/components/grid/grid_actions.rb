# toolbar items come from actions

module WulinMaster
  module GridActions
    extend ActiveSupport::Concern

    included do
      ORIGINAL_ACTIONS = %w(add delete edit filter)
      SENSITIVE_ACTIONS = %w(add delete edit hotkey_add hotkey_delete)
      PERMISSION_ACTIONS = {}

      class << self
        attr_reader :actions_pool
        def actions_pool
          @actions_pool ||= []
        end
      end
    end

    module ClassMethods
      # action DSL, add an action to the actions_pool
      def action(a_name, options={})
        new_action = {name: a_name}.merge(options)
        # append authrized option to an action which need permission
        if PERMISSION_ACTIONS.keys.map(&:to_s).include?(a_name.to_s)
          new_action.reverse_merge!(:authorized? => lambda { |user| user.has_permission_with_name?(PERMISSION_ACTIONS[a_name.to_s]) })
        end
        self.actions_pool << new_action
        add_hotkey_action(a_name, options)
      end

      def add_actions(*args)
        args.each do |arg|
          self.action(arg)
        end
      end

      def remove_actions(*args)
        args.each do |arg|
          self.actions_pool.delete_if { |action| action[:name] == arg.to_s}
        end
      end

      def load_default_actions(options={})
        ORIGINAL_ACTIONS.each do |oa|
          self.action(oa, options)
        end
        # special actions needed to be load as default
        # action :hotkey_add, visible: false
        # action :hotkey_delete, visible: false
      end

      def add_hotkey_action(action_name, action_options)
        action_name = action_name.to_s
        if action_name == 'add' and !self.actions_pool.find{|x| x[:name].to_s == 'hotkey_add'}
          self.actions_pool << {name: :hotkey_add, visible: false}.merge(action_options)
        elsif action_name == 'delete' and !self.actions_pool.find{|x| x[:name].to_s == 'hotkey_delete'}
          self.actions_pool << {name: :hotkey_delete, visible: false}.merge(action_options)
        end
      end

      # ------------------------------------------ API, interface open to other plugins ------------------------------------------
      def add_default_action(action)
        ORIGINAL_ACTIONS << action
      end

      def add_sensitive_action(action)
        SENSITIVE_ACTIONS << action
      end

      def set_permission_to_action(action_name, permission_name)
        PERMISSION_ACTIONS.merge!(action_name => permission_name)
      end
    end

    # the actions of a grid instance, filtered by screen param from class's actions_pool
    def actions
      return self.class.actions_pool if self.params["screen"].blank?
      self.class.actions_pool.select {|action| valid_action?(action)} #.uniq {|action| action[:name]}
    end

    # the actions on the toolbar
    def toolbar_actions
      actions.reject {|action| action[:toolbar_item] == false || action[:visible] == false}
    end

    # the actions on the grid header (not on the toolbar)
    def header_actions
      actions.select {|action| action[:toolbar_item] == false}
    end

    def action_configs
      actions.map {|a| a.reject{|k,v| k == :only or k == :except} }
    end

    def action_names
      actions.map {|a| a[:name].to_s}
    end

    private

    def valid_action?(action)
      valid_action_by_screen_configuration?(action) and
      valid_by_screen_authorize_create?(action) and
      valid_by_action_authorized?(action)
    end

    # 1. check if this action can be displayed in the screen due to :only or :except configuration
    def valid_action_by_screen_configuration?(action)
      (action[:only].blank? and action[:except].blank?) ||
      (action[:only].present? and params[:screen].present? and action[:only].include?(params[:screen].intern)) ||
      (action[:except].present? and params[:screen].present? and action[:except].exclude?(params[:screen].intern))
    end

    # 2. check if this screen creation authorized for current user if action is cud
    def valid_by_screen_authorize_create?(action)
      return true unless current_user
      self.class::SENSITIVE_ACTIONS.exclude?(action[:name].to_s) || screen.authorize_create?
    end

    # 3. check if this action authorized for current user
    def valid_by_action_authorized?(action)
      return true unless (action[:authorized?] and current_user)
      # authorized_proc = action.delete(:authorized?)
      authorized_proc = action[:authorized?]
      if authorized_proc.kind_of?(Proc)
        return authorized_proc.call(current_user)
      else
        return authorized_proc == true
      end
    end

  end
end