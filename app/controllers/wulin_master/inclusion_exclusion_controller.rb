module WulinMaster
  class InclusionExclusionController < ApplicationController
    before_filter :get_models, only: [:include, :exclude]

    def include
      if (ids = params[:ids]).present? and (group = @group_model.find params[:group_id] rescue false)
        @group_model.transaction do
          ids.each do |id|
            group.send(params[:exclude_model].underscore.pluralize) << @exclude_model.find(id)
          end
          group.save
        end
      end
      render :json => {:status => 'OK', :message => "Added #{ids.size} #{params[:exclude_model]}#{ids.size > 1 ? 's' : ''}."}
    rescue
      render :json => {:status => 'Error', :message => "Adding failed! Error: #{$!.message}"}
    end

    def exclude
      if (ids = params[:ids]).present?
        @include_model.where('id IN (?)', ids).destroy_all
      end
      render :json => {:status => 'OK', :message => "Removed #{ids.size} #{params[:exclude_model]}#{ids.size > 1 ? 's' : ''}!"}
    end
    
    def attach_details
      middle_model = params[:model].classify.constantize
      detail_column = middle_model.reflections[params[:detail_model].to_sym].foreign_key
      params[:detail_ids].each do |detail_id|
        middle_model.create({detail_column => detail_id, params[:master_column] => params[:master_id]})
      end
      render :json => {:status => 'OK', :message => "Attached #{params[:detail_ids].size} records."}
    end

    private
    def get_models
      @group_model = params[:group_model].classify.constantize
      @include_model = params[:include_model].classify.constantize
      @exclude_model = params[:exclude_model].classify.constantize
    end
  end
end