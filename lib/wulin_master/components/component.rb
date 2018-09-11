# frozen_string_literal: true

require 'wulin_master/components/component_styling'

module WulinMaster
  class Component
    include ComponentStyling

    attr_accessor :params, :screen, :controller, :custom_config

    # apply a config, dispatch it to a config pool (like option_pool, styles_pool etc)
    def self.apply_config(key, value, params = {})
      # Proceed when component class respond to the config method and it is a writter method
      return unless respond_to?(key) && ((arguments_count = method(key).arity) != 0)

      if arguments_count == 1
        send(key, value)
      elsif (arguments_count == -1) || (arguments_count == -2) # if this method accept options, pass the grid's params as options
        # when argument_count is -1, sometimes it can accept self.params (like :fill_window), sometimes it can't (like :title)
        begin
          send(key, value, params)
        rescue StandardError
          send(key, value)
        end
      end
    end

    def initialize(screen_instance = nil, config = {})
      @screen = screen_instance
      @params = screen_instance.try(:params)
      @controller = screen_instance.try(:controller)
      @custom_config = config
    end

    def panel?
      false
    end

    def grid?
      false
    end
  end
end
