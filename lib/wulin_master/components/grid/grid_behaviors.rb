# frozen_string_literal: true

# Grid behaviors, triggered by certain events

module WulinMaster
  module GridBehaviors
    extend ActiveSupport::Concern

    included do
      ORIGINAL_BEHAVIORS = %w[update validate highlight get_operate_ids clear_filters].freeze

      class << self
        attr_accessor :behaviors_pool
        def behaviors_pool
          @behaviors_pool ||= []
        end
      end
    end

    module ClassMethods
      # behavior DSL, add a behavior to the behaviors_pool
      def behavior(b_name, options = {})
        new_behavior = {name: b_name}.merge(options)
        behaviors_pool << new_behavior unless behaviors_pool.include?(new_behavior)
      end

      def add_behaviors(*args)
        args.each do |arg|
          behavior(arg)
        end
      end

      def remove_behaviors(*args)
        args.each do |arg|
          behaviors_pool.delete_if { |behavior| behavior[:name] == arg.to_s }
        end
      end

      def load_default_behaviors(options = {})
        ORIGINAL_BEHAVIORS.each do |ob|
          behavior(ob, options)
        end
      end

      # interface open to other plugins
      def add_default_behavior(behavior)
        ORIGINAL_BEHAVIORS << behavior
      end
    end

    # the behaviors of a grid instance, filtered by screen param from class's behaviors_pool
    def behaviors
      return self.class.behaviors_pool if params["screen"].blank?

      self.class.behaviors_pool.select { |behavior| valid_behavior?(behavior) }
    end

    # return the behavior with options, except the :only or :except option
    def behavior_configs
      behaviors.map { |b| b.reject { |k, _v| (k == :only) || (k == :except) } }
    end

    def behavior_names
      behaviors.map { |b| b[:name].to_s }
    end

    private

    def valid_behavior?(behavior)
      valid_behavior_by_screen_configuration?(behavior) &&
        valid_by_behavior_authorized?(behavior)
    end

    # 1. check if this behavior can be applied in the screen due to :only or :except configuration
    def valid_behavior_by_screen_configuration?(behavior)
      (behavior[:only].blank? && behavior[:except].blank?) ||
        (behavior[:only].present? && params[:screen].present? && behavior[:only].include?(params[:screen].intern)) ||
        (behavior[:except].present? && params[:screen].present? && behavior[:except].exclude?(params[:screen].intern))
    end

    # 2. check if this behavior authorized for current user
    def valid_by_behavior_authorized?(behavior)
      return true unless behavior[:authorized?] && current_user

      authorized_proc = behavior.delete(:authorized?)
      return authorized_proc == true unless authorized_proc.is_a?(Proc)

      authorized_proc.call(current_user)
    end
  end
end
