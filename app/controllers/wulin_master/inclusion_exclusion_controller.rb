module WulinMaster
  class InclusionExclusionController < ApplicationController
    before_action :prepare_models

    def include
      if (ids = params[:ids]).present? && (begin
                                             group = @group_model.find params[:group_id]
                                           rescue StandardError
                                             false
                                           end)
        @group_model.transaction do
          ids.each do |id|
            group.send(params[:exclude_model].underscore.pluralize) << @exclude_model.find(id)
          end
          group.save
        end
      end
      render json: {status: 'OK', message: "Added #{ids.size} #{params[:exclude_model].titleize}#{ids.size > 1 ? 's' : ''}."}
    rescue StandardError
      render json: {status: 'Error', message: "Adding failed! Error: #{$ERROR_INFO.message}"}
    end

    def exclude
      if (ids = params[:ids]).present?
        @include_model.where('id IN (?)', ids).destroy_all
      end
      render json: {status: 'OK', message: "Removed #{ids.size} #{params[:exclude_model].titleize}#{ids.size > 1 ? 's' : ''}!"}
    end

    private

    def prepare_models
      @group_model = params[:group_model].classify.constantize
      @include_model = params[:include_model].classify.constantize
      @exclude_model = params[:exclude_model].classify.constantize
    end
  end
end
