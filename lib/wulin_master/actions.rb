# frozen_string_literal: true

require 'wulin_master/authorization'

module WulinMaster
  module Actions
    include Authorization
    extend ActiveSupport::Concern

    included do
      before_action :require_authorization # Defined in Authorization module
    end

    def index
      respond_to do |format|
        format.html do
          render 'index', layout: (request.xhr? ? false : 'application')
        end
        format.json do
          return find_by_ids if params[:record_ids].present?

          fire_callbacks :initialize_query

          # Create initial query object
          @query ||= grid.model

          fire_callbacks :query_initialized

          # Make sure the relation method is called to correctly initialize it
          # We had issues where it's not initialized through the relation method when using
          #  the where method
          grid.model.relation if grid.model.respond_to?(:relation)

          # Add the necessary where statements to the query
          @query_without_filter = @query
          @count_without_filter = count_without_filter

          construct_filters

          fire_callbacks :query_filters_ready

          # Add order
          parse_ordering unless @skip_order

          # Add includes (OUTER JOIN)
          add_includes

          # Add joins (INNER JOIN)
          add_joins

          fire_callbacks :query_ready

          @aggregation_result = aggregate(@query.dup) if aggregation?

          # Get total counts
          @offset = params[:offset].present? ? params[:offset].to_i : 0
          if @offset.zero?
            @count_query = @query.clone
          else
            @count = smart_query_count @query
          end

          # Add limit and offset
          parse_pagination
          # Get all the objects
          @objects = (@query.is_a?(Array) ? @query : @query.all.to_a)

          # If we are on the first page and the dataset size is smaller than the page size, then we return the dataset size
          if @count_query
            @count = @objects.size < @per_page ? @objects.size : smart_query_count(@count_query)
          end
          fire_callbacks :objects_ready
          # Render json response
          render json: render_json
        end
      end
    rescue AUTH_ERROR_CLASS => e
      if /WulinOauthAuthenticationError/i.match?(e.class.to_s)
        render(json: {success: 401, msg: e, wulin_oauth: true}, status: 401)
      else
        raise e
      end
    end

    def update
      ids = params[:id].to_s.split(',')
      @records = grid.model.find(ids)
      if params_permit.present?
        record = @records.first
        updated_attributes = get_attributes(params_permit, :update, record)
        raise record.errors.full_messages.join(',') unless record.errors.empty?
        grid.model.transaction do
          @records.each do |r|
            r.update!(updated_attributes)
          end
        end
      end
      render json: {success: true}
    rescue StandardError
      render json: {success: false, error_message: $ERROR_INFO.message}
    end

    def destroy
      ids = params[:id].to_s.split(',')
      @records = grid.model.find(ids)
      success = true
      error_message = ""
      grid.model.transaction do
        @records.each do |record|
          next if record.destroy
          success = false
          error_message += record.errors.full_messages.join(",\n")
          raise ActiveRecord::Rollback
        end
      end
      if success
        render json: {success: true}
      else
        render json: {success: false, error_message: error_message}
      end
    rescue StandardError
      render json: {success: false, error_message: $ERROR_INFO.message}
    end

    def create
      @record = grid.model.new
      attrs = get_attributes(params_permit, :create, @record)
      custom_errors = @record.errors
      @record.assign_attributes(attrs)
      message = if !custom_errors.empty?
        {success: false, error_message: custom_errors}
      elsif @record.save
        {success: true, id: @record.id}
      else
        {success: false, error_message: @record.errors}
      end
      respond_to do |format|
        format.json { render json: message }
      end
    end

    def wulin_master_new_form
      render 'new_form', layout: false
    rescue ActionView::MissingTemplate
      render '/new_form', layout: false
    end

    def wulin_master_edit_form
      render 'edit_form', layout: false
    rescue ActionView::MissingTemplate
      render '/edit_form', layout: false
    end

    protected

    def construct_filters
      return unless params[:filters]
      params[:filters].each do |f|
        @query = grid.apply_filter(@query, f[:column], f[:value], f[:operator])
      end
    end

    def parse_ordering
      @order_column = grid.default_sorting_state[:column]
      if params[:sort_col].present? && grid.columns.map(&:full_name).map(&:to_s).include?(params[:sort_col])
        @order_column = params[:sort_col]
      elsif params[:sort_col].present?
        Rails.logger.warn "Sorting parameter ignored because not included in the grid columns: #{grid.columns.map(&:full_name).inspect}"
      end

      @order_direction = grid.default_sorting_state[:direction]
      @order_direction = params[:sort_dir].upcase if params[:sort_dir] =~ /^(A|DE)SC$/i

      @query = grid.apply_order(@query, @order_column, @order_direction)
      @query_without_filter = grid.apply_order(@query_without_filter, @order_column, @order_direction)
    end

    def parse_pagination
      # The slick.remotemodel's loadingSize is 200, so here we'd better set 200 too.
      @per_page = params[:count].to_i.zero? ? 200 : params[:count].to_i
      @page = (@offset / @per_page) + 1

      @query = @query.is_a?(Array) ? @query.from((@page - 1) * @per_page).to(@per_page) : @query.limit(@per_page).offset((@page - 1) * @per_page)
    end

    def add_includes
      includes = grid.includes
      @query = @query.includes(includes).references(includes) if !includes.empty? && @query.respond_to?(:includes)
      @query_without_filter = @query_without_filter.includes(includes).references(includes) if !includes.empty? && @query_without_filter.respond_to?(:includes)
    end

    def add_joins
      joins = grid.joins
      @query = @query.joins(joins) if !joins.empty? && @query.respond_to?(:joins)
      @query_without_filter = @query_without_filter.joins(joins) if !joins.empty? && @query_without_filter.respond_to?(:joins)
    end

    def render_json
      # Render ruby objects
      t = Time.current
      @object_array = grid.arraify(@objects)
      data = {
        offset: @offset,
        total: @count,
        totalNoFilter: @count_without_filter,
        count: @per_page,
        rows: @object_array
      }

      data.merge!(aggregation: @aggregation_result) if aggregation?

      Rails.logger.info "----------------- Rendered JSON in #{Time.current - t} sec. ------------------------"

      data.to_json
    end

    def count_without_filter
      smart_query_count @query_without_filter
    end

    def get_attributes(attrs, type, object = nil)
      return {} if attrs.blank?
      attrs.delete_if { |k, _v| k == "id" }
      new_attributes = grid.map_attrs(attrs, type, object)
      attrs.merge!(new_attributes)
      attrs
    end

    private

    def params_permit
      model_class = grid.model.is_a?(ActiveRecord::Relation) ? grid.model.klass : grid.model
      model_key = ActiveModel::Naming.param_key(model_class).to_sym
      params.require(:item).permit! if params[:item].presence
      params.require(model_key).permit! if params[model_key].presence
      params[:item].presence || params[model_key].presence
    end

    def fire_callbacks(name)
      return unless self.class.callbacks
      cbs = self.class.find_callbacks(name)

      return if cbs.blank?
      cbs.each do |cb|
        if cb.class == Proc
          cb.call
        elsif respond_to?(cb, true)
          send(cb)
        end
      end
    end

    def query_count(query)
      case query.class.to_s
        when /activerecord_relation/i
          query.unscope(:order).unscope(:select).unscope(:limit).unscope(:offset).count("DISTINCT #{grid.model.table_name}.id")
        when /array/i
          query.size
        else
          query.all.to_a
      end
    end

    def smart_query_count(query)
      query = query.except(:select).select("#{grid.model.table_name}.id").unscope(:order) if query.respond_to?(:except)

      return query_count(query) if grid.options[:estCount].blank?

      if ActiveRecord::Base.connection.instance_values['config'][:adapter] != 'postgresql'
        Rails.logger.warn 'Estimate count ignored because not using PostgreSQL'

        return query_count(query)
      end

      sql = if query == grid.model
        "SELECT reltuples AS count_estimate FROM pg_class WHERE relname = '" + query.table_name + "'"
      else
        "SELECT count_estimate('" + query.to_sql.gsub("'", "''") + "')"
      end

      est_count = ActiveRecord::Base.connection.execute(sql).to_a.first['count_estimate'].to_i
      return query.count if est_count < grid.options[:estCount][:threshold].to_i
      est_count
    end

    def aggregation?
      grid.behavior_configs.any? { |b| b[:name].to_sym == :aggregation }
    end

    def aggregate(query)
      aggregation_behavior = grid.behavior_configs.find { |b| b[:name].to_sym == :aggregation }
      aggregation_behavior[:with].call(query)
    end

    def find_by_ids
      ids = params[:record_ids].split(',').map(&:strip)
      return {} unless ids.present?
      fire_callbacks :initialize_query

      # Create initial query object
      @query ||= grid.model

      fire_callbacks :query_initialized

      # Make sure the relation method is called to correctly initialize it
      # We had issues where it's not initialized through the relation method when using
      #  the where method
      grid.model.relation if grid.model.respond_to?(:relation)

      # Add the necessary where statements to the query
      @query_without_filter = @query
      @count_without_filter = count_without_filter

      construct_filters

      fire_callbacks :query_filters_ready

      # Add includes (OUTER JOIN)
      add_includes

      # Add joins (INNER JOIN)
      add_joins

      fire_callbacks :query_ready

      @aggregation_result = aggregate(@query.dup) if aggregation?

      # Find by ids
      @query = @query.where(id: ids)

      # Get all the objects
      @objects = @query

      @count = @objects.size

      fire_callbacks :objects_ready

      # Render json response
      render json: render_json
    end
  end
end
