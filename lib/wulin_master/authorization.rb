module WulinMaster
  module Authorization
    # Called as before_filter
    def require_authorization
      is_authorized = case params[:action]
      when 'index'
        screen.authorized?(current_user)
      when 'create'
        screen.authorize_create?(current_user)
      when 'update'
        screen.authorize_update?(current_user)
      when 'destroy'
        screen.authorize_destroy?(current_user)
      else
        true
      end
      
      is_authorized ? authorized : unauthorized
    end
    
    def unauthorized
      Rails.logger.info "Unauthorized #{params[:action].inspect} request to screen #{screen.class}"
      respond_to do |format|
        format.html { render :text => "Unauthorized", :status => 401}
        format.json { render :json => {:status => :unauthorized}, :status => 401 }
      end
      false
    end

    def authorized
      Rails.logger.info "Authorized #{params[:action].inspect} request to screen #{screen.class}"
      true
    end
  end
end