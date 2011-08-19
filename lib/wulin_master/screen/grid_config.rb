module WulinMaster 
  class GridConfig
    class << self
      # define some inheritable class variables
      attr_accessor :grid_name, :grid_context, :config_block
    end
    
    def self.inherited(subclass)
      subclass.grid_name = subclass.name.sub(/Grid/, "").underscore
    end
    
    def self.config(&block)
      @grid_context = Grid.new(@grid_name.to_sym)
      @config_block = block if block_given?
    end
    
    def self.method_missing(method, *args)
      @grid_context.send(method, *args) if @grid_context
    end
  end
end