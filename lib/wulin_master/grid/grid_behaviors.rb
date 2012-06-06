# Grid behaviors, triggered by certain events

module WulinMaster
  module GridBehaviors
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        ORIGINAL_BEHAVIORS = %w(update validate highlight get_operate_ids)

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
        @behaviors_pool << new_behavior
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
    def behaviors
      return self.class.behaviors_pool if self.params["screen"].blank?
      self.class.behaviors_pool.select {|behavior| valid_behavior?(behavior, self.params["screen"])}
    end

    private

    def valid_behavior?(behavior, screen_name)
      (behavior[:only].blank? and behavior[:except].blank?) ||
      (behavior[:only].present? and screen_name and behavior[:only].include?(screen_name.intern)) ||
      (behavior[:except].present? and screen_name and behavior[:except].exclude?(screen_name.intern))
    end
    
  end
end