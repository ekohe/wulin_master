module WulinMaster
  class DynamicColumns
    attr_accessor :columns_pool, :grid_class

    def initialize (grid_class)
      self.columns_pool = []
      self.grid_class = grid_class
    end

    def columns
      columns_pool
    end

    def column (name, options={})
      self.columns_pool << Column.new(name, self.grid_class, options)
    end
  end
end