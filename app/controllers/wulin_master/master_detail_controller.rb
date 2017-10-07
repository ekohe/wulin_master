module WulinMaster
  class MasterDetailController < ApplicationController
    def detail_controller
      real_class_name = begin
                          params[:middle_model].classify.constantize.reflections[params[:model].to_s].class_name
                        rescue StandardEroor
                          params[:model]
                        end
      render json: {status: 'OK', controller: real_class_name.tableize}
    end

    def attach_details
      middle_model = params[:model].classify.constantize
      detail_column = middle_model.reflections[params[:detail_model].to_s].foreign_key
      middle_model.transaction do
        params[:detail_ids].each do |detail_id|
          middle_model.create!(detail_column => detail_id, params[:master_column] => params[:master_id])
        end
      end
      render json: {status: 'OK', message: "#{self.class.helpers.pluralize(params[:detail_ids].size, 'record')} attached."}
    end
  end
end
