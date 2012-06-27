module WulinMaster
  module PanelRelation
    extend ActiveSupport::Concern
    
    module ClassMethods
      # Specify the inclusion grid for InclusionExclusionPanel
      def inclusion_grid(grid_klass, options={})
        if options[:screen]
          inclusion_grid = grid_klass.constantize.new({screen: options[:screen], format: 'json'})
          options.merge!({inclusion_grid: inclusion_grid.name})
        end
      end

      # Specify the exclusion grid for InclusionExclusionPanel
      def exclusion_grid(grid_klass, options={})
        if options[:screen]
          exclusion_grid = grid_klass.constantize.new({screen: options[:screen], format: 'json'})
          options.merge!({exclusion_grid: exclusion_grid.name})
        end
      end
    end

    # ----------------------------- Instance Methods ------------------------------------
    
  end
end