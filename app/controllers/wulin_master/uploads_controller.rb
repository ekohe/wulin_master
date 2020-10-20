# frozen_string_literal: true

module WulinMaster
  class UploadsController < ApplicationController
    def create
      blob = ActiveStorage::Blob.create_after_upload!(
        io: params[:file],
        filename: params[:file].original_filename,
        content_type: params[:file].content_type
      )

      render json: { path: polymorphic_path(blob) }
    end
  end
end
