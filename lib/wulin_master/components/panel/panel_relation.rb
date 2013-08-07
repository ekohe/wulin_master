module WulinMaster
  module PanelRelation
    extend ActiveSupport::Concern
    
    included do
      attr_accessor :relations_pool
      def relations_pool
        self.relations_pool ||= {}
      end
    end

    module ClassMethods
      # Specify the inclusion grid for InclusionExclusionPanel
      def inclusion_grid(grid_klass, options={})
        if options[:screen]
          inclusion_grid = grid_klass.constantize.new({screen: options[:screen], no_render: true})
          self.relations_pool[options[:screen]] ||= {}
          self.relations_pool[options[:screen]].merge!({inclusion_grid: inclusion_grid.name})
        end
      end

      # Specify the exclusion grid for InclusionExclusionPanel
      def exclusion_grid(grid_klass, options={})
        if options[:screen]
          exclusion_grid = grid_klass.constantize.new({screen: options[:screen], no_render: true})
          self.relations_pool[options[:screen]] ||= {}
          self.relations_pool[options[:screen]].merge!({exclusion_grid: exclusion_grid.name})
        end
      end
    end

    # ----------------------------- Instance Methods ------------------------------------
    def inclusion_grid
      self.params["screen"] ? self.class.relations_pool[self.params["screen"]][:inclusion_grid] : nil
    end

    def exclusion_grid
      self.params["screen"] ? self.class.relations_pool[self.params["screen"]][:exclusion_grid] : nil
    end
  end
end