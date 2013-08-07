module WulinMaster
  class FetchOptionsController < ::ActionController::Metal
    
    def index
      if authorized? and params[:text_attr].present?
        if klass.column_names.include? params[:text_attr]
          objects = klass.select("id, #{params[:text_attr]}").order("#{params[:text_attr]} ASC").all
        else
          objects = klass.all.sort{|x,y| x.send(params[:text_attr]).to_s.downcase <=> y.send(params[:text_attr]).to_s.downcase}
        end
        self.response_body = objects.collect{|o| {:id => o.id, params[:text_attr].to_sym => o.send(params[:text_attr])} }.to_json
      else
        # Should reply something different here, at least status code should be 403
        self.response_body = [].to_json
      end
    rescue
      self.response_body = [].to_json
    end
    
    
    def specify_fetch
      if authorized? and params[:name_attr].present? and params[:code_attr].present?
        if klass.column_names.include?(params[:name_attr]) and klass.column_names.include?(params[:code_attr])
          objects = klass.select("id, #{params[:name_attr]}, #{params[:code_attr]}").order("#{params[:name_attr]} ASC").all
        else
          objects = klass.all.sort{|x,y| x.send(params[:name_attr]).to_s.downcase <=> y.send(params[:name_attr]).to_s.downcase}
        end
        self.response_body = objects.to_json
      else
        self.response_body = [].to_json
      end
    rescue
      self.response_body = [].to_json
    end

    def fetch_distinct_options
      if authorized? and params[:text_attr].present?
        object_arr = klass.select(params[:text_attr]).order("#{params[:text_attr]} ASC").uniq.pluck(params[:text_attr]).delete_if(&:blank?)
        self.response_body = object_arr.to_json
      else
        self.response_body = [].to_json
      end
    rescue
      self.response_body = [].to_json
    end
    
    
    private
    
    def authorized?
      return true unless self.respond_to?(:current_user)
      current_user && column_belongs_to_grid? && column_screen && authorized_for_user?
    end
    
    def authorized_for_user?
      controller = column_controller_class.new
      screen = column_screen.new(controller)
      !screen.respond_to?(:authorized?) || (screen.respond_to?(:authorized?) && screen.authorized?(current_user))
    end
    
    def column_belongs_to_grid?
      !!column
    end
    
    def column_screen
      params[:screen].safe_constantize || "#{klass.name}Screen".safe_constantize
    end

    def column_controller_class
      "#{klass.name.pluralize}Controller".safe_constantize
    end
    
    def klass
      column.reflection.try(:klass) || params[:klass].safe_constantize
    end
    
    def column
      grid_class.columns.find {|x| x.name.to_s == params[:column]}
    end
    
    def grid_class
      params[:grid].classify.safe_constantize
    end
    
  end
end