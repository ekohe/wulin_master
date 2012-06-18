module WulinMaster
  module GridRelation
    extend ActiveSupport::Concern
    
    module ClassMethods
      # Set master grid, invoked from grid.apply_custom_config method
      def master_grid(master_grid_klass, options={})
        if options[:screen]
          detail_model = self.model
          master_grid = master_grid_klass.constantize.new({screen: options[:screen], format:'json'})   # format as json to skip the toolbar and styling initialize
          through = options[:through] || detail_model.reflections[master_grid.model.to_s.underscore.intern].foreign_key

          # disable the multiSelect for master grid
          master_grid_klass.constantize.options_pool << {:multiSelect => false, :only => [options[:screen].intern]}

          # call affiliation behavior for detail grid
          behavior :affiliation, master_grid_name: master_grid.name, only: [options[:screen].intern], through: through
        end
      end
    end
    
    # ----------------------------- Instance Methods ------------------------------------
    
  end
end