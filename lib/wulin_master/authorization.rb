# frozen_string_literal: true

#
# lib/wulin_master/actions.rb
#  before_action :require_authorization #Defined in Authorization module
#
# wulin_permits/extensions/screen_controller.rb
#  before_action :create_permissions
#
#
# There are two callbacks for verifing users permisson in the controller
#
# if you dont integrated the wulin_permits, the callback just be the require_authorization
#
# if you integrated the wulin_permits, the callback will be the require_authorization and create_permissions
# the two callback will invove the unauthorized if the user don't have the permission
#

module WulinMaster
  module Authorization
    extend ActiveSupport::Concern

    # Called as before_action
    def require_authorization
      return true unless respond_to?(:current_user)

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
      msg = "Permission needed: #{required_permission.name}"

      respond_to do |format|
        format.html { render plain: msg, status: :unauthorized }
        format.json { render json: {status: :unauthorized, msg: msg}, status: :unauthorized }
      end
    end

    def authorized
      Rails.logger.info "Authorized #{params[:action].inspect} request to screen #{screen.class}"
    end

    #
    # This is a help method for the required permission
    #
    def required_permission
      #
      # return the permission record if we have the Permission model
      #
      @required_permission ||= defined?(Permission) ? wulin_permits_required_permission : OpenStruct.new(name: [controller_name, action_name].join("#"))
    end
  end
end
