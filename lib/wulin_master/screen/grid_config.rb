module WulinMaster 
  class GridConfig
    cattr_accessor :grid_name, :grid_context, :config_block, :screen_context
    
    def self.inherited(subclass)
      @@grid_name = subclass.name.sub(/Grid/, "").underscore
    end
    
    def self.config(&block)
      @@grid_context = Grid.new(@@grid_name.to_sym)
      @@config_block = block if block_given?
    end
    
    def self.method_missing(method, *args)
      @@screen_context.send(method, *args) if @@screen_context
    end
  end
end