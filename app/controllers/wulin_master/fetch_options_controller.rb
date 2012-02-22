module WulinMaster
  class FetchOptionsController < ::ActionController::Metal
    
    def index
      if logined? and params[:klass].present? and params[:text_attr].present? and klass = params[:klass].classify.constantize
        if klass.column_names.include? params[:text_attr]
          objects = klass.select("id, #{params[:text_attr]}").order("#{params[:text_attr]} ASC").all
        else
          objects = klass.all.sort{|x,y| x.send(params[:text_attr]).to_s.downcase <=> y.send(params[:text_attr]).to_s.downcase}
        end
        self.response_body = objects.to_json
      else
        self.response_body = [].to_json
      end
    rescue
      self.response_body = [].to_json
    end
    
    
    def specify_fetch
      if logined? and params[:klass].present? and params[:name_attr].present? and params[:code_attr].present? and klass = params[:klass].classify.constantize
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
    
    
    private
    
    def logined?
      session[:user] || session[:user_id] || session[:current_user] || session[:current_user_id] || (User.respond_to?(:current_user) && User.current_user)
    end
    
  end
end