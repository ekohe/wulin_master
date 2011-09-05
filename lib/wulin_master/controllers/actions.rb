module WulinMaster
  module Actions
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

          # Add the necessary where statements to the query
          construct_filters

          fire_callbacks :query_filters_ready
  
          # Getting to total count of the dataset
          @count = @query.count
          
          # Add limit and offset
          parse_pagination
          
          # Add order
          parse_ordering
          
          # Add select
          add_select
          
          fire_callbacks :query_ready

          # Get all the objects
          @objects = @query.all
          
          # Render json response
          render :json => render_json
        end
      end
    end
    
    def update
      params[:item].delete_if {|k,v| v == "null"}
      @record = grid.model.find(params[:id]) 
      message = if @record.update_attributes(params[:item])
        {:success => true }
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
      message = begin 
        grid.model.transaction do
          @records.each {|record| record.destroy }
        end
        {:success => true }
      rescue Exception => e
         {:success => false, :error_message => e.message}
      end
      respond_to do |format|
        format.json { render :json => message }
      end
    end
    
    
    def create
      @record = grid.model.new(params[grid.name.to_sym])
      message = if @record.save
        {:success => true, id: @record.id }
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
      @order_column = params[:sort_col] if params[:sort_col] and !params[:sort_col].blank?
      @order_direction = "ASC"
      @order_direction = params[:sort_dir].upcase if params[:sort_dir] and ["ASC", "DESC"].include?(params[:sort_dir].upcase)

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
      @query = @query.select(grid.sql_select)
    end
    
    def render_json
      # Render ruby objects
      @object_array = grid.arraify(@objects)

      json = JSON({:offset => @offset,
               :total =>  @count,
               :count =>  @per_page,
               :rows =>   @object_array})
      
      json
    end
  end
end