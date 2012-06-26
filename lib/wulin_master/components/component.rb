require File.join(File.dirname(__FILE__), 'component_styling')

module WulinMaster
  class Component
    include ComponentStyling

    attr_accessor :params, :controller, :custom_config

    def initialize(params={}, controller_instance=nil, config={})
      self.params = params
      self.controller = controller_instance
      self.custom_config = config
    end

    protected

    def apply_default_config(default_config)
      default_config.each do |k,v|
        apply_config(k,v)
      end if default_config.is_a?(Hash)
    end

    def apply_custom_config
      self.custom_config.each do |k,v|
        apply_config(k,v)
      end if self.custom_config.is_a?(Hash)
    end

    private

    # calling a config
    def apply_config(key, value)
      if self.class.respond_to?(key) and (arguments_count = self.class.method(key).arity) != 0    # if grid class respond to the config method and it is a writter method
        if arguments_count == 1
          self.class.send(key, value)
        elsif arguments_count == -1 or arguments_count == -2  # if this method accept options, pass the grid's params as options
          # when argument_count is -1, sometimes it can accept self.params (like :fill_window), sometimes it can't (like :title)
          begin
            self.class.send(key, value, self.params)
          rescue 
            self.class.send(key, value)
          end
        end
      end
    end
  end
end