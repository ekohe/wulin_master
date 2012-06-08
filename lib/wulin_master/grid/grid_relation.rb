module WulinMaster
  module GridRelation
    extend ActiveSupport::Concern
    
    module ClassMethods
      # Set master grid
      def master_grid(grid_klass, options={})
        if options[:screen]
          behavior :affiliation, master_grid_name: grid_klass.constantize.new({screen: options[:screen]}).name, only: [options[:screen].intern]
        end
      end
    end
    
    # ----------------------------- Instance Methods ------------------------------------
    
  end
end