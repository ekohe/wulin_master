module WulinMaster
  module Actions
    IGNORE_PARAMS = %w(offset count sort_col sort_dir filters action controller format)
    def index
      respond_to do |format|
        format.html do
          begin
            render 'index', :layout => (request.xhr? ? false : 'application')
          rescue ActionView::MissingTemplate
            render '/index', :layout => (request.xhr? ? false : 'application')
          end
        end
        format.json do
          # Create initial query object
          @query = grid.model

          # Make sure the relation method is called to correctly initialize it
          # We had issues where it's not initialized through the relation method when using
          #  the where method
          grid.model.relation if grid.model.respond_to?(:relation)
          
          # Add the necessary where statements to the query
          construct_filters

          fire_callbacks :query_filters_ready

          # Add limit and offset
          parse_pagination

          # Add order
          parse_ordering

          # Add select
          add_select

          # Add includes (OUTER JOIN)
          add_includes

          # Add joins (INNER JOIN)
          add_joins

          fire_callbacks :query_ready

          # Get all the objects
          @objects = (@query.is_a?(Array) ? @query : @query.all.to_a)
          
          # Getting to total count of the dataset
          @count = @objects.count

          # Render json response
          render :json => render_json
        end
      end
    end

    def update
      updated_attributes = get_updated_attributes(params[:item])
      @record = grid.model.find(params[:id]) 
      message = if @record.update_attributes(updated_attributes)
        attributes = grid.arraify([@record.reload]).first.inject({}) {|a,hash|  hash.merge(a) }.merge(:id => @record.id)
        {:success => true, :attrs => attributes}
      else
        {:success => false, :error_message => @record.errors.full_messages.join("\n")}
      end
      respond_to do |format|
        format.json { render :json => message }
      end
    end

    def destroy
      ids = params[:id].to_s.split(',')
      @records = grid.model.find(ids)
      begin 
        # grid.model.transaction do
        @records.each {|record| record.destroy }
        # end
        message = {:success => true }
      rescue e
        message = {:success => false, :error_message => e.message}
      end
      respond_to do |format|
        format.json { render :json => message }
      end
    end


    def create
      attrs = get_create_attributes(params[grid.model.to_s.underscore.gsub('/', '_')])
      @record = grid.model.new(attrs)
      message = if @record.save
        {:success => true, :id => @record.id }
      else
        {:success => false, :error_message => @record.errors}
      end
      respond_to do |format|
        format.json { render :json => message }
      end
    end

    protected

    def construct_filters
      return unless params[:filters]
      params[:filters].each do |f|
        @query = grid.apply_filter(@query, f[:column], f[:value])
      end
    end

    def parse_ordering
      @order_column = grid.sql_columns.first
      @order_column = params[:sort_col] if params[:sort_col].present?
      @order_direction = "ASC"
      @order_direction = params[:sort_dir].upcase if params[:sort_dir] =~ /^(A|DE)SC$/i

      @query = @query.order("#{@order_column} #{@order_direction}")
    end

    def parse_pagination
      # The slick.remotemodel's loadingSize is 200, so here we'd better set 200 too.
      @per_page = params[:count].to_i.zero? ? 200 : params[:count].to_i
      @offset = params[:offset] ? params[:offset].to_i : 0
      @page = (@offset / @per_page) + 1

      @query = @query.limit(@per_page).offset((@page-1) * @per_page)
    end

    def add_select
      #@query = @query.select(grid.sql_select)
    end

    def add_includes
      @query = @query.includes(grid.includes) if ActiveRecord::Relation === @query or @query == grid.model
    end

    def add_joins
      @query = @query.joins(grid.joins) if ActiveRecord::Relation === @query or @query == grid.model
    end

    def render_json
      # Render ruby objects
      @object_array = grid.arraify(@objects)

      json = JSON({:offset => @offset,
        :total =>  @count,
        :count =>  @per_page,
        :rows  =>  @object_array})
      json
    end

    def get_create_attributes(attrs={})
      associations = grid.model.reflections
      new_attributes = {}
      attrs.each do |k,v|
        if associations.keys.include?(k.to_sym)
          association_attributes = attrs.delete(k)
          if associations[k.to_sym].macro == :has_and_belongs_to_many and association_attributes != 'null'
            new_attributes[k.to_sym] = associations[k.to_sym].klass.find(association_attributes).to_a
          end
        elsif !grid.model.column_names.include?(k.to_s)
          attrs.delete(k)
        end
      end
      attrs.merge!(new_attributes)
      attrs
    end

    def get_updated_attributes(attrs)
      attrs.delete_if {|k,v| v == "null" || k == "id" }
      associations = grid.model.reflections
      new_attributes = {}
      attrs.each do |k,v|
        if associations.keys.include?(k.to_sym)
          association_attributes = attrs.delete(k)
          if associations[k.to_sym].macro == :belongs_to and association_attributes['id'] != 'null'
            new_attributes[grid.model.reflections[k.to_sym].foreign_key] = association_attributes['id']
          elsif associations[k.to_sym].macro == :has_and_belongs_to_many and association_attributes['id'] != 'null'
            new_attributes[k.to_sym] = associations[k.to_sym].klass.find(association_attributes['id']).to_a
          end
      #  elsif !grid.model.column_names.include?(k.to_s)
      #    attrs.delete(k)
        end
      end
      attrs.merge!(new_attributes)
      attrs
    end

  end
end
