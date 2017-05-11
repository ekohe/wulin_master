module WulinMaster
  module PanelRelation
    extend ActiveSupport::Concern

    included do
      class << self
        attr_reader :relations_pool
        def relations_pool
          @relations_pool ||= {}
        end
      end
    end

    module ClassMethods
      # Specify the inclusion grid for InclusionExclusionPanel
      def inclusion_grid(grid_klass, options = {})
        if options[:screen]
          grid_name = WulinMaster::Utilities.get_grid_name(grid_klass, options[:screen])
          relations_pool[options[:screen]] ||= {}
          relations_pool[options[:screen]].merge!(inclusion_grid: grid_name)
        end
      end

      # Specify the exclusion grid for InclusionExclusionPanel
      def exclusion_grid(grid_klass, options = {})
        if options[:screen]
          grid_name = WulinMaster::Utilities.get_grid_name(grid_klass, options[:screen])
          relations_pool[options[:screen]] ||= {}
          relations_pool[options[:screen]].merge!(exclusion_grid: grid_name)
        end
      end
    end

    # ----------------------------- Instance Methods ------------------------------------
    def inclusion_grid
      params["screen"] ? self.class.relations_pool[params["screen"]][:inclusion_grid] : nil
    end

    def exclusion_grid
      params["screen"] ? self.class.relations_pool[params["screen"]][:exclusion_grid] : nil
    end
  end
end
