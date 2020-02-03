# frozen_string_literal: true

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
      render json: {status: 'OK', message: "#{I18n.t('wulin_master.text.Added')} #{ids.size} #{I18n.t(params[:exclude_model].titleize)}"}
    rescue StandardError
      render json: {status: 'Error', message: "Adding failed! Error: #{$ERROR_INFO.message}"}
    end

    def exclude
      if (ids = params[:ids]).present?
        @include_model.where('id IN (?)', ids).destroy_all
      end
      render json: {status: 'OK', message: "#{I18n.t('wulin_master.text.Removed')} #{ids.size} #{I18n.t(params[:exclude_model].titleize)}"}
    end

    private

    def prepare_models
      @group_model = params[:group_model].classify.constantize
      @include_model = params[:include_model].classify.constantize
      @exclude_model = params[:exclude_model].classify.constantize
    end
  end
end
