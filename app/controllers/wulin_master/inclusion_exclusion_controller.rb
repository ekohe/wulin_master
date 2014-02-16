module WulinMaster
  class InclusionExclusionController < ApplicationController
    before_filter :get_models

    def include
      if (ids = params[:ids]).present? and (group = @group_model.find params[:group_id] rescue false)
        @group_model.transaction do
          ids.each do |id|
            group.send(params[:exclude_model].underscore.pluralize) << @exclude_model.find(id)
          end
          group.save
        end
      end
      render :json => {:status => 'OK', :message => "Added #{ids.size} #{params[:exclude_model].titleize}#{ids.size > 1 ? 's' : ''}."}
    rescue
      render :json => {:status => 'Error', :message => "Adding failed! Error: #{$!.message}"}
    end

    def exclude
      if (ids = params[:ids]).present? && (@objects = @include_model.where(id: ids).to_a).present?
        @objects.each do |object|
          object.destroy
          raise object.errors.full_messages.join(',') unless object.errors.empty?
        end
      end
      render :json => {:status => 'OK', :message => "Removed #{ids.size} #{params[:exclude_model].titleize}#{ids.size > 1 ? 's' : ''}!"}
    rescue
      render json: {:success => 'NO', :message => $!.message }
    end

    private
    def get_models
      @group_model = params[:group_model].classify.constantize
      @include_model = params[:include_model].classify.constantize
      @exclude_model = params[:exclude_model].classify.constantize
    end
  end
end
