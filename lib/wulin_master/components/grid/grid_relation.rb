module WulinMaster
  module GridRelation
    extend ActiveSupport::Concern
    
    module ClassMethods
      # Set master grid, invoked from grid.apply_custom_config method
      def master_grid(master_grid_klass, options={}, inclusion=true)
        if options[:screen]
          detail_model = self.model
          master_grid = master_grid_klass.constantize.new({screen: options[:screen], format: 'json'})   # format as json to skip the toolbar and styling initialize
          
          # master_model must has_many detail_model, detail_model may belongs_to master_model OR has_many master_model
          reflection = detail_model.reflections[master_grid.model.to_s.underscore.intern] || detail_model.reflections[master_grid.model.to_s.underscore.pluralize.intern]

          through = options[:through] || reflection.foreign_key

          # disable the multiSelect for master grid
          master_grid_klass.constantize.multi_select false, only: [options[:screen].intern]

          # call affiliation or reverse_affiliation behavior for detail grid
          operator = if reflection.macro == :belongs_to
            inclusion ? 'equals' : 'not_equals'
          elsif reflection.macro == :has_many
            inclusion ? 'include' : 'exclude'
          end

          # add association column to self for filtering
          unless self.columns_pool.find {|c| c.name == reflection.name and c.options[:only].include?(options[:screen].intern)}
            column reflection.name, visible: false, editable: false, option_text_attribute: "id", only: [options[:screen].intern]
          end

          behavior :affiliation, master_grid_name: master_grid.name, only: [options[:screen].intern], through: through, operator: operator
        end
      end

      # Inclusion-Exclusion relation, include of master grid
      def include_of(master_grid_klass, options={})
        self.master_grid(master_grid_klass, options, true)
        behavior :include_exclude_trivia, only: [options[:screen].intern]
      end

      # Inclusion-Exclusion relation, exclude of master grid
      def exclude_of(master_grid_klass, options={})
        self.master_grid(master_grid_klass, options, false)
        behavior :include_exclude_trivia, only: [options[:screen].intern]
      end

      # when there is no master grid but you want the detail grid can be filtered by a given model
      def master_model(model_name, options={})
        if options[:screen]
          detail_model = self.model
          reflection = detail_model.reflections[model_name.intern]

          # add association column
          unless self.columns_pool.find {|c| c.name == reflection.name and c.options[:only].include?(options[:screen].intern)}
            column reflection.name, visible: false, editable: false, option_text_attribute: "id", only: [options[:screen].intern]
          end
        end
      end
    end

    # ----------------------------- Instance Methods ------------------------------------
    
  end
end