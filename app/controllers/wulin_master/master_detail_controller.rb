# frozen_string_literal: true

module WulinMaster
  class MasterDetailController < ApplicationController
    def detail_controller
      real_class_name = begin
                          params[:middle_model].classify.constantize.reflections[params[:model].to_s].class_name
                        rescue StandardError
                          params[:model]
                        end
      render json: {status: 'OK', controller: real_class_name.tableize}
    end

    def attach_details
      middle_model = params[:model].classify.constantize
      detail_column = middle_model.reflections[params[:detail_model].to_s.underscore].foreign_key
      middle_model.transaction do
        params[:detail_ids].each do |detail_id|
          middle_model.create!(detail_column => detail_id, params[:master_column] => params[:master_id])
        end
      end
      render json: {status: 'OK', message: "#{self.class.helpers.pluralize(params[:detail_ids].size, 'record')} attached."}
    rescue
      render json: {success: false, message: $ERROR_INFO.message, error_message: $ERROR_INFO.message}
    end

    def detach_details
      detail_ids = params[:detail_ids]
      raise "Please select records to detach." unless detail_ids.present?

      middle_model = params[:model].classify.constantize
      detail_column = middle_model.reflections[params[:detail_model].to_s.underscore].foreign_key
      middle_model.where(detail_column => detail_ids, params[:master_column] => params[:master_id]).destroy_all
      render json: {status: 'OK', message: "#{self.class.helpers.pluralize(detail_ids.size, 'record')} detached."}
    rescue
      render json: {success: false, error_message: $ERROR_INFO.message}
    end
  end
end
