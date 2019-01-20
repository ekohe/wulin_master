# frozen_string_literal: true

module WulinMaster
  module GridRelation
    extend ActiveSupport::Concern

    included do
      class << self
        attr_reader :current_filter_column, :current_detail_model
      end
    end

    module ClassMethods
      # Set master grid, invoked from grid.apply_custom_config method
      def master_grid(master_grid_klass_name, options = {}, inclusion = true)
        @current_filter_column = nil

        raise "'#{master_grid_klass_name}' is not valid grid name." unless master_grid_klass = master_grid_klass_name.to_s.classify.safe_constantize
        return if options[:screen].blank?
        detail_model = model
        master_grid_name = WulinMaster::Utilities.get_grid_name(master_grid_klass_name, options[:screen])

        # master_model must has_many detail_model, detail_model may belongs_to master_model OR has_many master_model
        master_relation_name = master_grid_klass.model.name.underscore.tr('/', '_')

        reflection = detail_model.reflections[master_relation_name] ||
                     detail_model.reflections[master_relation_name.pluralize]

        through = options[:through] || reflection.foreign_key

        # call affiliation or reverse_affiliation behavior for detail grid
        operator = find_operator(reflection, inclusion)

        # add association column to self for filtering
        unless columns_pool.find { |c| (c.full_name == reflection.foreign_key) && c.valid_in_screen(options[:screen]) }
          column(
            reflection.name,
            visible: false,
            editable: false,
            formable: false,
            source: "id",
            detail_relation_name: @current_detail_model,
            only: [options[:screen].intern]
          )
          @current_filter_column = reflection.name
        end

        behavior :add_candidate_filter, filter: reflection.foreign_key, only: [options[:screen].intern]
        behavior :affiliation, master_grid_name: master_grid_name, only: [options[:screen].intern], through: through, operator: operator
        behavior :empty_detail, master_grid_name: master_grid_name, only: [options[:screen].intern]
        behavior :clear_detail_when_multi_select, master_grid_name: master_grid_name, only: [options[:screen].intern]
      end

      def find_operator(reflection, inclusion)
        if reflection.macro == :belongs_to
          inclusion ? 'equals' : 'not_equals'
        elsif reflection.macro == :has_many
          inclusion ? 'include' : 'exclude'
        end
      end

      # Inclusion-Exclusion relation, include of master grid
      def include_of(master_grid_klass, options = {})
        master_grid(master_grid_klass, options, true)
        behavior :include_exclude_trivia, only: [options[:screen].intern] if options[:screen]
      end

      # Inclusion-Exclusion relation, exclude of master grid
      def exclude_of(master_grid_klass, options = {})
        master_grid(master_grid_klass, options, false)
        behavior :include_exclude_trivia, only: [options[:screen].intern] if options[:screen]
      end

      # when there is no master grid but you want the detail grid can be filtered by a given model
      def master_model(model_name, options = {})
        @current_filter_column = nil

        return unless options[:screen]

        detail_model = model
        reflection = detail_model.reflections[model_name.to_s]

        # add association column
        unless columns_pool.find { |c| (c.full_name == reflection.foreign_key) && c.valid_in_screen(options[:screen]) }
          column(
            reflection.name,
            visible: false,
            editable: false,
            formable: false,
            source: "id",
            detail_relation_name: @current_detail_model,
            only: [options[:screen].intern]
          )
          @current_filter_column = reflection.foreign_key
        end

        behavior :add_candidate_filter, filter: reflection.foreign_key, only: [options[:screen].intern]
      end

      # when the detail grid data is come from the model which is not the corresponding model of the grid (eg: the self related model)
      # you can specify it handily
      def detail_model(model_name, options = {})
        @current_detail_model = nil

        return unless options[:screen]

        @current_detail_model = model_name
        # if master_model already invoked (the @current_filter_column has been set and added corresponding column)
        # remove it and re-add it, append @current_detail_model as an option
        if @current_filter_column &&
           (same_column = columns_pool.find { |c| (c.full_name == @current_filter_column) && c.options[:only].include?(options[:screen].intern) })
          columns_pool.delete(same_column)
          column(
            @current_filter_column,
            visible: false,
            editable: false,
            formable: false,
            source: "id",
            detail_relation_name: @current_detail_model,
            only: [options[:screen].intern]
          )
          @current_detail_model = nil
        end
      end
    end

    # ----------------------------- Instance Methods ------------------------------------
  end
end
