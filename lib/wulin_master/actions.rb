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
          # Create initial query object
          @query = grid.model

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
          
          # Apply virtual attribute order
          apply_virtual_order
          
          # Apply virtual attribute filter
          apply_virtual_filter

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
        updated_attributes = get_updated_attributes(param_attrs)
        grid.model.transaction do
          @records.each do |record|
            record.update_attributes!(updated_attributes)
          end
        end
      end
      render json: {:success => true}
    rescue
      render json: {:success => false, :error_message => $!.message }
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
            error_message << record.errors.full_messages.join("\n")
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
    
    def apply_virtual_filter
      if (filters = grid.virtual_filter_columns).present?
        filters.each do |filterer|
          @objects.select! do |x|
            re_table, re_column = filterer[0].split(".")
            
            if x.respond_to?(re_table.to_sym)
              value = x.send(re_table)
              if re_column
                value = x.send(re_table).try(re_column)
              end
            
              if filterer[2] == "equals"
                value.to_s =~ /^#{Regexp.escape(filterer[1])}/i
              elsif filterer[2] == "not_equals"
                value.to_s !~ /^#{Regexp.escape(filterer[1])}/i
              else
                true
              end
            else
              true
            end
            
          end
        end
      end
    end
    
    def apply_virtual_order
      if (sorter = grid.virtual_sort_column).present?
        @objects.sort! do |x, y|
          re_table, re_column = sorter[0].split(".")
          if x.respond_to?(re_table.to_sym) and y.respond_to?(re_table.to_sym)
            x_value, y_value = x.send(re_table), y.send(re_table)
            if re_column
              x_value, y_value = x.send(re_table).try(re_column), y.send(re_table).try(re_column)
            end

            x_value = format_boolean_to_number(x_value) if y_value.is_a?(TrueClass) or y_value.is_a?(FalseClass)
            y_value = format_boolean_to_number(y_value) if y_value.is_a?(TrueClass) or y_value.is_a?(FalseClass)
            x_value = x_value.to_s if x_value.blank?
            y_value = y_value.to_s if y_value.blank?

            if sorter[1] == 'ASC'
              x_value <=> y_value
            elsif sorter[1] == 'DESC'
              y_value <=> x_value
            end
          end
        end
      end
    end

    def construct_filters
      return unless params[:filters]
      params[:filters].each do |f|
        @query = grid.apply_filter(@query, f[:column], f[:value], f[:operator])
      end
    end

    def parse_ordering
      @order_column = grid.sql_columns.first
      if params[:sort_col].present? and (grid.columns.map(&:name).map(&:to_s).include?(params[:sort_col]))
        @order_column = params[:sort_col]
      elsif params[:sort_col].present?
        Rails.logger.warn "Sorting parameter ignored because not included in the grid columns: #{grid.columns.map(&:name).inspect}" 
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
        :rows  =>  @object_array}.to_json
        Rails.logger.info "Rendered JSON in #{Time.now-t} sec."
        json
      end

      def get_create_attributes(attrs={})
        associations = grid.model.reflections
        new_attributes = {}
        attrs.each do |k,v|
          if associations.keys.include?(k.to_sym)
            association_attributes = attrs.delete(k)
            if associations[k.to_sym].macro == :belongs_to and association_attributes['id'] != 'null'
              new_attributes[grid.model.reflections[k.to_sym].foreign_key] = association_attributes['id']
            elsif associations[k.to_sym].macro.to_s =~ /^has_many$|^has_and_belongs_to_many$/
              association_attributes = association_attributes.uniq.compact.delete_if{|x| x.blank? }
              if association_attributes == 'null' or association_attributes.blank?
                new_attributes[k.to_sym] = []
              else
                new_attributes[k.to_sym] = associations[k.to_sym].klass.find(association_attributes).to_a
              end
            end
          elsif k.to_s !~ /_attributes$/ and grid.model.column_names.exclude?(k.to_s) and !grid.model.new.respond_to?("#{k.to_s}=")
            attrs.delete(k)
          end
          new_attributes[k.to_sym] = nil if v == 'null'
        end
        attrs.merge!(new_attributes)
        attrs
      end

      def get_updated_attributes(attrs)
        attrs.delete_if {|k,v| k == "id" }
        associations = grid.model.reflections
        new_attributes = {}
        attrs.each do |k,v|
          if associations.keys.include?(k.to_sym)
            association_attributes = attrs.delete(k)

            case associations[k.to_sym].macro
            when :belongs_to then
              if association_attributes['id'] == 'null'
                new_attributes[grid.model.reflections[k.to_sym].foreign_key] = nil
              elsif association_attributes['id'].present?
                new_attributes[grid.model.reflections[k.to_sym].foreign_key] = association_attributes['id']
              elsif has_one_reverse_relation?(associations[k.to_sym].klass, grid.model)
                nested_attr_key = (k =~ /_attributes$/ ? k : "#{k}_attributes")
                new_attributes[nested_attr_key] = association_attributes
              end
            when :has_and_belongs_to_many then
              # batch update action will pass id with array like ['1', '2'], not hash like { id => ['1', '2']}
              if Array === association_attributes
                the_ids = association_attributes.first.split(',')
              elsif Hash === association_attributes
                the_ids = ((association_attributes['id'] == 'null' or association_attributes['id'].blank?) ? [] : association_attributes['id'])
              else
                the_ids = []
              end
              the_ids = the_ids.uniq.delete_if(&:blank?)
              if the_ids.blank?
                new_attributes[k.to_sym] = []
              else
                new_attributes[k.to_sym] = associations[k.to_sym].klass.find(the_ids).to_a
              end
            when :has_many then
              # Should convert association_attributes for grid cell editor ajax request.
              if Hash === association_attributes and association_attributes.values.all? {|value| value.key?('id')}
                 association_attributes = association_attributes.values.map{|x| x['id']}.uniq.delete_if(&:blank?)
              end
              
              if association_attributes == 'null' or association_attributes.all? {|value| value == 'null'}
                new_attributes[k.to_sym] = []
              else
                new_attributes[k.to_sym] = associations[k.to_sym].klass.find(association_attributes.uniq.delete_if(&:blank?)).to_a
              end
            end
          elsif k.to_s !~ /_attributes$/ and grid.model.column_names.exclude?(k.to_s) and !@records.first.respond_to?("#{k.to_s}=")
            attrs.delete_if {|key, value| key.to_s == k.to_s }
          elsif v == 'null'
            new_attributes[k.to_sym] = nil
          end
        end
        attrs.merge!(new_attributes)
        attrs
      end

      def format_boolean_to_number(boolean_value)
        boolean_value ? 1 : 0
      end

      def has_one_reverse_relation?(related_klass, klass)
        (reflect = related_klass.reflections.find{|x| x[1].klass == klass}[1]) and reflect.macro == :has_one
      end

    end
  end
