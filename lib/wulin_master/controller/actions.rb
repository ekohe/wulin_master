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
        if Mime::Type.lookup_by_extension("xls")
          format.xls do
            render_xls if self.respond_to?(:render_xls)
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
          render_json
          
          render :json => @json
        end
      end
    end
    
    def update
      params[:item].delete_if {|k,v| v == "null"}
      id = params[:item].delete(:id)
      record = grid.model.find(id) 
      message = if record.update_attributes(params[:item])
        {:success => true }
      else
        {:success => false, :error_message => record.errors.full_messages.join("\n")}
      end
      respond_to do |format|
        format.json { render :json => message }
      end
    end
    
    def destroy
      ids = params[:id].to_s.split(',')
      records = grid.model.find(ids) 
      message = begin 
        grid.model.transaction do
          records.each {|record| record.destroy }
        end
        {:success => true }
      rescue => e
         {:success => false, :error_message => e}
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
      @order_column = "#{@order_column}" unless ((@order_column =~ /^\[(.*)\]$/) != nil) # MSSQL specific
      @order_direction = "ASC"
      @order_direction = params[:sort_dir].upcase if params[:sort_dir] and ["ASC", "DESC"].include?(params[:sort_dir].upcase)

      @query = @query.order("#{@order_column} #{@order_direction}")
    end
    
    def parse_pagination
      @per_page = (params[:count] && params[:count].to_i!=0) ? params[:count].to_i : 10
      @offset = params[:offset] ? params[:offset].to_i : 0
      @page = (@offset / @per_page) + 1
      
      @query = @query.limit(@per_page).offset((@page-1) * @per_page)
    end
    
    def add_select
      @query = @query.select(grid.sql_select)
    end
    
    def render_json
      # t = Time.now
      # # Render ruby hashes
      # @object_hashes = grid.hashify(@objects)
      # logger.info "Time to make hashes: #{((Time.now-t)*1000).to_i}ms"
      # 

      t = Time.now
      # Render ruby objects
      @object_array = grid.arraify(@objects)

      t2 = Time.now

      @json = JSON({:offset => @offset,
               :total =>  @count,
               :count =>  @per_page,
               :rows =>   @object_array})

      logger.info "Rendering JSON (#{((Time.now-t)*1000).to_i}ms) - #{((t2-t)*1000).to_i}ms for objects generation and #{((Time.now-t2)*1000).to_i}ms for jsonification"
    end
  end
end