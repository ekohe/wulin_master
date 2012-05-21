# toolbar items come from actions

module WulinMaster
  module GridActions
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        ORIGINAL_ACTIONS = %w(add delete edit filter)
        #ORIGINAL_BEHAVIOR = %(update filter sort order)

        class << self
          attr_reader :actions_pool
        end
      end
    end
    
    # --------------------- Class Methods ----------------------------
    module ClassMethods
      def initialize_actions_pool
        @actions_pool ||= []
      end

      # action DSL, add an action to the actions_pool
      def action(a_name, options={})
        new_action = {name: a_name}.merge(options)
        @actions_pool.unshift new_action
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

      def load_default_actions(screens=nil)
        ORIGINAL_ACTIONS.each do |oa|
          self.action(oa, {screens: screens})
        end
      end

      # interface open to other plugins
      def add_default_action(action)
        ORIGINAL_ACTIONS << action
      end
    end

    # ----------------------- Instance Methods ------------------------------
    
    # return the toolbar
    # def toolbar
    #   self.class.toolbar
    # end

    # the actions of a grid instance, filtered by screen param from class's actions_pool 
    def actions
      self.class.actions_pool.select {|action| action[:screens].nil? or (self.params["screen"] and action[:screens].include?(self.params["screen"].intern)) }
    end

    def action_names
      actions.map{|a| a[:name]}
    end

    # the actions on the toolbar
    def toolbar_actions
      actions.reject {|action| action[:toolbar_item] == false}
    end

    # the actions on the grid header (not on the toolbar)
    def header_actions
      actions.select {|action| action[:toolbar_item] == false}
    end

    def action_names
      actions.map {|a| a[:name].to_s}
    end

  end
end