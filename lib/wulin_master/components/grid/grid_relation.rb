module WulinMaster
  module GridRelation
    extend ActiveSupport::Concern

    included do
      class_eval do
        class << self
          attr_reader :current_filter_column, :current_detail_model
        end
      end
    end
    
    module ClassMethods
      # Set master grid, invoked from grid.apply_custom_config method
      def master_grid(master_grid_klass, options={}, inclusion=true)
        @current_filter_column = nil

        if options[:screen]
          detail_model = self.model
          master_grid = master_grid_klass.constantize.new({screen: options[:screen], no_render: true})   # set no_render true to skip the config applying
          
          # master_model must has_many detail_model, detail_model may belongs_to master_model OR has_many master_model
          reflection = detail_model.reflections[master_grid.model.to_s.underscore.intern] || detail_model.reflections[master_grid.model.to_s.underscore.pluralize.intern]

          through = options[:through] || reflection.foreign_key

          # disable the multiSelect for master grid
          multi_select_options = master_grid_klass.constantize.options_pool.select{|x| x.keys.include?(:multiSelect)}
          multi_select_option = multi_select_options.find{|x| (x[:only] && x[:only].include?(options[:screen].intern)) || !x[:only]}
          master_grid_klass.constantize.multi_select false, only: [options[:screen].intern] unless (multi_select_option and multi_select_option[:multiSelect])

          # call affiliation or reverse_affiliation behavior for detail grid
          operator = if reflection.macro == :belongs_to
            inclusion ? 'equals' : 'not_equals'
          elsif reflection.macro == :has_many
            inclusion ? 'include' : 'exclude'
          end

          # add association column to self for filtering
          unless self.columns_pool.find {|c| c.full_name == reflection.foreign_key and c.valid_in_screen(options[:screen]) }
            column reflection.name, visible: false, editable: false, formable: false, option_text_attribute: "id", detail_relation_name: @current_detail_model, only: [options[:screen].intern]
            @current_filter_column = reflection.name
          end

          behavior :add_candidate_filter, filter: reflection.foreign_key, only: [options[:screen].intern]
          behavior :affiliation, master_grid_name: master_grid.name, only: [options[:screen].intern], through: through, operator: operator
          behavior :empty_detail, master_grid_name: master_grid.name, only: [options[:screen].intern]
        end
      end

      # Inclusion-Exclusion relation, include of master grid
      def include_of(master_grid_klass, options={})
        self.master_grid(master_grid_klass, options, true)
        behavior :include_exclude_trivia, only: [options[:screen].intern] if options[:screen]
      end

      # Inclusion-Exclusion relation, exclude of master grid
      def exclude_of(master_grid_klass, options={})
        self.master_grid(master_grid_klass, options, false)
        behavior :include_exclude_trivia, only: [options[:screen].intern] if options[:screen]
      end

      # when there is no master grid but you want the detail grid can be filtered by a given model
      def master_model(model_name, options={})
        @current_filter_column = nil

        if options[:screen]
          detail_model = self.model
          reflection = detail_model.reflections[model_name.intern]

          # add association column
          unless self.columns_pool.find {|c| c.full_name == reflection.foreign_key and c.options[:only].include?(options[:screen].intern)}
            column reflection.name, visible: false, editable: false, formable: false, option_text_attribute: "id", detail_relation_name: @current_detail_model, only: [options[:screen].intern]
            @current_filter_column = reflection.foreign_key
          end

          behavior :add_candidate_filter, filter: reflection.foreign_key, only: [options[:screen].intern]
        end
      end

      # when the detail grid data is come from the model which is not the corresponding model of the grid (eg: the self related model)
      # you can specify it handily 
      def detail_model(model_name, options={})
        @current_detail_model = nil

        if options[:screen]
          @current_detail_model = model_name
          # if master_model already invoked (the @current_filter_column has been set and added corresponding column)
          # remove it and re-add it, append @current_detail_model as an option
          if @current_filter_column and (same_column = self.columns_pool.find {|c| c.full_name == @current_filter_column and c.options[:only].include?(options[:screen].intern)})
            self.columns_pool.delete(same_column)
            column @current_filter_column, visible: false, editable: false, formable: false, option_text_attribute: "id", detail_relation_name: @current_detail_model, only: [options[:screen].intern]
            @current_detail_model = nil
          end
        end
      end
    end

    # ----------------------------- Instance Methods ------------------------------------
    
  end
end