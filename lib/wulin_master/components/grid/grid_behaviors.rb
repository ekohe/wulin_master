# Grid behaviors, triggered by certain events

module WulinMaster
  module GridBehaviors
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        ORIGINAL_BEHAVIORS = %w(update validate highlight get_operate_ids clear_filters)

        class << self
          attr_reader :behaviors_pool
        end
      end
    end
    
    # --------------------- Class Methods ----------------------------
    module ClassMethods
      def initialize_behaviors
        @behaviors_pool ||= []
      end

      # behavior DSL, add a behavior to the behaviors_pool
      def behavior(b_name, options={})
        new_behavior = {name: b_name}.merge(options)
        @behaviors_pool << new_behavior unless @behaviors_pool.include?(new_behavior)
      end

      def add_behaviors(*args)
        args.each do |arg|
          self.behavior(arg)
        end
      end

      def remove_behaviors(*args)
        args.each do |arg|
          @behaviors_pool.delete_if { |behavior| behavior[:name] == arg.to_s}
        end
      end

      def load_default_behaviors(options={})
        ORIGINAL_BEHAVIORS.each do |ob|
          self.behavior(ob, options)
        end
      end

      # interface open to other plugins
      def add_default_behavior(behavior)
        ORIGINAL_BEHAVIORS << behavior
      end
    end

    # ----------------------- Instance Methods ------------------------------

    # the behaviors of a grid instance, filtered by screen param from class's behaviors_pool 
    def behaviors(current_user=nil)
      return self.class.behaviors_pool if self.params["screen"].blank?
      self.class.behaviors_pool.select {|behavior| valid_behavior?(behavior, self.params["screen"], current_user)}
    end

    # return the behavior with options, except the :only or :except option
    def behavior_configs(current_user=nil)
      the_behaviors = behaviors(current_user)
      the_behaviors.map {|b| b.reject{|k,v| k == :only or k == :except} }
    end

    def behavior_names(current_user=nil)
      the_behaviors = behaviors(current_user)
      the_behaviors.map {|b| b[:name].to_s}
    end

    private

    def valid_behavior?(behavior, screen_name, user)
      valid_by_screen_configuration?(behavior, screen_name, user) and
      valid_by_behavior_authorized?(behavior, user)
    end

    # 1. check if this behavior can be applied in the screen due to :only or :except configuration
    def valid_by_screen_configuration?(behavior, screen_name, user)
      (behavior[:only].blank? and behavior[:except].blank?) ||
      (behavior[:only].present? and screen_name and behavior[:only].include?(screen_name.intern)) ||
      (behavior[:except].present? and screen_name and behavior[:except].exclude?(screen_name.intern))
    end

    # 2. check if this behavior authorized for current user
    def valid_by_behavior_authorized?(behavior, user)
      return true unless (behavior[:authorized?] and user)

      if behavior[:authorized?].kind_of?(Proc)
        return behavior[:authorized?].call(user)
      else
        return behavior[:authorized?] == true
      end
    end
    
  end
end