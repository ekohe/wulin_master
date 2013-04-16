require File.join(File.dirname(__FILE__), 'authorization')

module WulinMaster
  module Actions
    include Authorization

    def self.included(base)
      base.class_eval do
        before_filter :require_authorization # Defined in Authorization module
      end
    end

    def index
      respond_to do |format|
        format.html do
          render 'index', :layout => (request.xhr? ? false : 'application')
        end
        format.json do
          fire_callbacks :initialize_query
          
          # Create initial query object
          @query = @query || grid.model

          fire_callbacks :query_initialized

          # Make sure the relation method is called to correctly initialize it
          # We had issues where it's not initialized through the relation method when using
          #  the where method
          grid.model.relation if grid.model.respond_to?(:relation)

          # Add the necessary where statements to the query
          construct_filters

          fire_callbacks :query_filters_ready

          # Add order
          parse_ordering unless @skip_order

          # Add includes (OUTER JOIN)
          add_includes

          # Add joins (INNER JOIN)
          add_joins

          fire_callbacks :query_ready

          # Getting to total count of the dataset if we aren't on the first page
          @offset = params[:offset].present? ? params[:offset].to_i : 0
          if @offset == 0
            @count_query = @query.clone
          else
            @count = @query.count
          end

          # Add limit and offset
          parse_pagination

          # Get all the objects
          @objects = (@query.is_a?(Array) ? @query : @query.all.to_a)

          # If we are on the first page and the dataset size is smaller than the page size, then we return the dataset size
          if @count_query
            @count = (@objects.size < @per_page) ? @objects.size : @count_query.count
          end

          fire_callbacks :objects_ready

          # Render json response
          render :json => render_json
        end
      end
    end

    def update
      ids = params[:id].to_s.split(',')
      @records = grid.model.find(ids)
      param_attrs = params[:item].presence || params[ActiveModel::Naming.param_key(grid.model).to_sym].presence

      if param_attrs.present?
        updated_attributes = get_attributes(param_attrs, :update, @records.first)

        hstore_att = updated_attributes.select{|k, v| k.to_s.index('->') }
        other_att = updated_attributes.select{|k, v| !k.to_s.index('->')}

        @records.each do |record|
          hstore_att.each do |k,v|
            record.send("#{k}=".to_sym, v)
          end

          record.save
        end

        grid.model.transaction do
          @records.each do |record|
            record.update_attributes!(other_att)
          end
        end
      end
      render json: {:success => true}
    # rescue
    #   render json: {:success => false, :error_message => $!.message }
    end

    def destroy
      ids = params[:id].to_s.split(',')
      @records = grid.model.find(ids)
      success = true
      error_message = ""
      grid.model.transaction do
        @records.each do |record| 
          unless record.destroy
            success = false
            error_message << record.errors.full_messages.join(",\n")
            break
          end
        end
      end
      if success
        render json: {:success => true }
      else
        render json: {:success => false, :error_message => error_message}
      end
    rescue
      render json: {:success => false, :error_message => $!.message}
    end


    def create
      param_key = ActiveModel::Naming.param_key(grid.model).to_sym

      attrs = get_attributes(params[param_key].presence || params[:item].presence, :create)

      hstore_att = attrs.select{|k, v| k.to_s.index('->') }
      other_att = attrs.select{|k, v| !k.to_s.index('->')}

      @record = grid.model.new(other_att)

      hstore_att.each do |k,v|
        @record.send("#{k}=".to_sym, v)
      end

      message = if @record.save
        {:success => true, :id => @record.id }
      else
        {:success => false, :error_message => @record.errors}
      end
      respond_to do |format|
        format.json { render :json => message }
      end
    end

    def wulin_master_new_form
      @grid = grid
      render 'new_form', layout: false
    rescue ActionView::MissingTemplate
      render '/new_form', layout: false
    end
    
    def wulin_master_edit_form
      @grid = grid
      render 'edit_form', layout: false
    rescue ActionView::MissingTemplate
      render '/edit_form', layout: false
    end

    def wulin_master_option_new_form
      @grid = grid
      render 'option_new_form', layout: false
    rescue ActionView::MissingTemplate
      render '/option_new_form', layout: false
    end

    protected
    
    def column_for x
      if x.index('->')
        splitted = x.split(/->/)
        column = splitted[0]
        subs = splitted[1..-1]
        return ([column] + subs.map{|x| "'#{x}'"}).join('->')
      else
        return x
      end
    end

    def construct_filters
      return unless params[:filters]
      params[:filters].each do |f|
        @query = grid.apply_filter(@query, column_for(f[:column]), f[:value], f[:operator])
      end
    end

    def parse_ordering
      @order_column = grid.sql_columns.first
      if params[:sort_col].present? and (grid.columns.map(&:full_name).map(&:to_s).include?(params[:sort_col]))
        @order_column = params[:sort_col]
      elsif params[:sort_col].present?
        Rails.logger.warn "Sorting parameter ignored because not included in the grid columns: #{grid.columns.map(&:full_name).inspect}" 
      end
      @order_direction = "ASC"
      @order_direction = params[:sort_dir].upcase if params[:sort_dir] =~ /^(A|DE)SC$/i

      @query = grid.apply_order(@query, @order_column, @order_direction)
    end

    def parse_pagination
      # The slick.remotemodel's loadingSize is 200, so here we'd better set 200 too.
      @per_page = params[:count].to_i.zero? ? 200 : params[:count].to_i
      # @offset = params[:offset] ? params[:offset].to_i : 0
      @page = (@offset / @per_page) + 1

      @query = @query.is_a?(Array) ? @query.from((@page-1) * @per_page).to(@per_page) : @query.limit(@per_page).offset((@page-1) * @per_page)
    end

    def add_includes
      includes = grid.includes
      @query = @query.includes(includes) if includes.size > 0 && @query.respond_to?(:includes)
    end

    def add_joins
      joins = grid.joins
      @query = @query.joins(joins) if joins.size > 0 && @query.respond_to?(:joins)
    end

    def render_json
      # Render ruby objects
      t = Time.now
      @object_array = grid.arraify(@objects)
      json = {:offset => @offset,
        :total =>  @count,
        :count =>  @per_page,
        :rows  =>  @object_array
      }.to_json
      Rails.logger.info "----------------- Rendered JSON in #{Time.now-t} sec. ------------------------"
      json
    end

    def get_attributes(attrs, type, object = nil)
      attrs.delete_if {|k,v| k == "id" }
      new_attributes = grid.map_attrs(attrs, type, object)
      attrs.merge!(new_attributes)
      attrs
    end

  end
end
