# toolbar items come from actions

module WulinMaster
  module GridActions
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        ORIGINAL_ACTIONS = %w(add delete edit filter)
        SENSITIVE_ACTIONS = %w(add delete edit hotkey_add hotkey_delete)

        class << self
          attr_reader :actions_pool
        end
      end
    end
    
    # --------------------- Class Methods ----------------------------
    module ClassMethods
      def initialize_actions
        @actions_pool ||= []
      end

      # action DSL, add an action to the actions_pool
      def action(a_name, options={})
        new_action = {name: a_name}.merge(options)
        @actions_pool << new_action
        add_hotkey_action(a_name, options)
      end

      def add_actions(*args)
        args.each do |arg|
          self.action(arg)
        end
      end

      def remove_actions(*args)
        args.each do |arg|
          @actions_pool.delete_if { |action| action[:name] == arg.to_s}
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

      # interface open to other plugins
      def add_default_action(action)
        ORIGINAL_ACTIONS << action
      end

      def add_hotkey_action(action_name, action_options)
        action_name = action_name.to_s
        if action_name == 'add' and !@actions_pool.find{|x| x[:name].to_s == 'hotkey_add'}
          @actions_pool << {name: :hotkey_add, visible: false}.merge(action_options) 
        elsif action_name == 'delete' and !@actions_pool.find{|x| x[:name].to_s == 'hotkey_delete'}
          @actions_pool << {name: :hotkey_delete, visible: false}.merge(action_options) 
        end
      end
    end

    # ----------------------- Instance Methods ------------------------------

    # the actions of a grid instance, filtered by screen param from class's actions_pool 
    def actions(current_user=nil)
      return self.class.actions_pool if self.params["screen"].blank?
      self.class.actions_pool.select {|action| valid_action?(action, self.params["screen"], current_user)}.uniq {|action| action[:name]}
    end

    # the actions on the toolbar
    def toolbar_actions(current_user=nil)
      the_actions = actions(current_user)
      the_actions.reject {|action| action[:toolbar_item] == false || action[:visible] == false}
    end

    # the actions on the grid header (not on the toolbar)
    def header_actions(current_user=nil)
      the_actions = actions(current_user)
      the_actions.select {|action| action[:toolbar_item] == false}
    end
    
    def action_configs(current_user=nil)
      the_actions = actions(current_user)
      the_actions.map {|a| a.reject{|k,v| k == :only or k == :except} }
    end

    def action_names(current_user=nil)
      the_actions = actions(current_user)
      the_actions.map {|a| a[:name].to_s}
    end

    private

    def valid_action?(action, screen_name, user)
      valid_by_screen_configuration?(action, screen_name, user) and 
      valid_by_screen_authorize_create?(action, screen_name, user) and 
      valid_by_action_authorized?(action, user)
    end

    # 1. check if this action can be displayed in the screen due to :only or :except configuration
    def valid_by_screen_configuration?(action, screen_name, user)
      (action[:only].blank? and action[:except].blank?) ||
      (action[:only].present? and screen_name and action[:only].include?(screen_name.intern)) ||
      (action[:except].present? and screen_name and action[:except].exclude?(screen_name.intern))
    end

    # 2. check if this screen creation authorized for current user if action is cud 
    def valid_by_screen_authorize_create?(action, screen_name, user)
      screen = screen_name.safe_constantize.try(:new)
      return true unless (user and screen)
      self.class::SENSITIVE_ACTIONS.exclude?(action[:name].to_s) || screen.authorize_create?(user)
    end

    # 3. check if this action authorized for current user
    def valid_by_action_authorized?(action, user)
      return true unless (action[:authorized?] and user)

      if action[:authorized?].kind_of?(Proc)
        return action[:authorized?].call(user)
      else
        return action[:authorized?] == true
      end
    end

  end
end