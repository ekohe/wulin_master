module WulinMaster
  class MasterDetailController < ApplicationController
    def get_detail_controller
      real_class_name = params[:middle_model].classify.constantize.reflections[params[:model].to_sym].class_name rescue params[:model]
      render :json => {:status => 'OK', :controller => real_class_name.tableize}
    end

    def attach_details
      Rails.logger.info "/\\"*50
      Rails.logger.info "params = #{params}"
      Rails.logger.info "/\\"*50

      middle_model = params[:model].classify.constantize
      Rails.logger.info "passed middle_model = params[:model].classify.constantize #{middle_model}"

      detail_column = middle_model.reflections[params[:detail_model].to_sym].foreign_key
      Rails.logger.info "passed detail_column = middle_model.reflections[params[:detail_model].to_sym].foreign_key"

      Rails.logger.info "middle_model = #{middle_model} detail_column #{detail_column} "
      
      middle_model.transaction do

        # Make sure we are the only one doing this so that validation can actually work properly
        ActiveRecord::Base.connection.execute("LOCK TABLE #{middle_model.table_name} IN ACCESS EXCLUSIVE MODE;")

        params[:detail_ids].each do |detail_id|
          middle_model.create!({detail_column => detail_id, params[:master_column] => params[:master_id]})
        end
      end
      render :json => {:status => 'OK', :message => "#{self.class.helpers.pluralize(params[:detail_ids].size, 'record')} attached."}
    end

    def attach_master_details
      Rails.logger.info "$/\\"*50
      Rails.logger.info "params = #{params}"
      Rails.logger.info "/\\"*50

      middle_model = params[:detail_model].classify.constantize
      Rails.logger.info "passed middle_model = params[:model].classify.constantize #{middle_model}"

      #detail_column = middle_model.reflections[params[:model].to_sym].foreign_key
      Rails.logger.info "passed detail_column = middle_model.reflections[params[:detail_model].to_sym].foreign_key"

      Rails.logger.info "middle_model = #{middle_model}  "
      
      middle_model.transaction do

        # Make sure we are the only one doing this so that validation can actually work properly
        ActiveRecord::Base.connection.execute("LOCK TABLE #{middle_model.table_name} IN ACCESS EXCLUSIVE MODE;")

        params[:detail_ids].each do |detail_id|
          middle_model.create!({params[:master_column] => params[:master_id]})
        end
      end
      render :json => {:status => 'OK', :message => "#{self.class.helpers.pluralize(params[:detail_ids].size, 'record')} attached."}
    end


  end
end