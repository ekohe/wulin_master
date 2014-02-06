module WulinMaster
  module Authorization
    # Called as before_filter
    def require_authorization
      return true unless self.respond_to?(:current_user)
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
        format.html { render :text =>  "Unauthorized, permission: #{screen.respond_to?('blocked_permission') ? screen.blocked_permission : nil}", :status => 401}
        format.json { render :json => {:status => :unauthorized, :permission => screen.respond_to?('blocked_permission') ? screen.blocked_permission : nil}, :status => 401 }
      end
    end

    def authorized
      Rails.logger.info "Authorized #{params[:action].inspect} request to screen #{screen.class}"
    end
  end
end