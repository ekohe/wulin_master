module WulinMaster
  module PanelRelation
    extend ActiveSupport::Concern
    
    included do
      class_eval do
        class << self
          attr_reader :relations_pool
        end
      end
    end

    module ClassMethods
      def initialize_relations
        @relations_pool ||= {}
      end  

      # Specify the inclusion grid for InclusionExclusionPanel
      def inclusion_grid(grid_klass, options={})
        if options[:screen]
          inclusion_grid = grid_klass.constantize.new({screen: options[:screen], no_render: true})
          @relations_pool[options[:screen]] ||= {}
          @relations_pool[options[:screen]].merge!({inclusion_grid: inclusion_grid.name})
        end
      end

      # Specify the exclusion grid for InclusionExclusionPanel
      def exclusion_grid(grid_klass, options={})
        if options[:screen]
          exclusion_grid = grid_klass.constantize.new({screen: options[:screen], no_render: true})
          @relations_pool[options[:screen]] ||= {}
          @relations_pool[options[:screen]].merge!({exclusion_grid: exclusion_grid.name})
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