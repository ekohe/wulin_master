# frozen_string_literal: true

module WulinMaster
  module Authorization
    extend ActiveSupport::Concern

    # Called as before_action
    def require_authorization
      return true unless respond_to?(:current_user)

      authorized
    end

    def unauthorized(permission_name = nil)
      Rails.logger.info "Unauthorized #{params[:action].inspect} request to screen #{screen.class}"
      msg = permission_name ? "Permission needed: #{permission_name}" : ''

      respond_to do |format|
        format.html { render plain: msg, status: :unauthorized }
        format.json { render json: {status: :unauthorized, msg: msg}, status: :unauthorized }
      end
    end

    def authorized
      Rails.logger.info "Authorized #{params[:action].inspect} request to screen #{screen.class}"
    end
  end
end
