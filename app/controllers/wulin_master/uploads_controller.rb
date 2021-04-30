# frozen_string_literal: true

module WulinMaster
  class UploadsController < ApplicationController
    # rubocop:disable Metrics/AbcSize
    def create
      if !params[:custom_uploader].blank?
        custom_uploader = params[:custom_uploader]
        raise "#{custom_uploader} should inherit RichMediaUploader" unless Object.const_get(custom_uploader).ancestors.include?(RichMediaUploader)

        uploader = Object.const_get(custom_uploader).new(params[:file])
        uploader.upload

        render json: { url: uploader.url }
      elsif using_disk_service?
        # Directly save the upload in a public folder
        #   if we are using disk service in the public folder

        # Generate unique folder name
        directory_name = File.join(ActiveStorage::Blob.service.root, SecureRandom.alphanumeric(6).scan(/../))

        # Create folder
        FileUtils.mkdir_p(directory_name)

        # Write file
        path = File.join(directory_name, File.basename(params[:file].original_filename))
        File.open(path, "wb") { |f| f.write(params[:file].read) }

        # Get relative public path
        public_path = Pathname.new(path).relative_path_from(Rails.public_path)

        render json: { url: '/' + public_path.to_s }
      else
        # Using disk service outside of public directory, S3 or other cloud services
        blob = ActiveStorage::Blob.create_after_upload!(
          io: params[:file],
          filename: params[:file].original_filename,
          content_type: params[:file].content_type
        )

        render json: { url: url_for(blob) }
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def using_disk_service?
      Object.const_defined?('ActiveStorage::Service::DiskService') &&
        ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService) &&
        ActiveStorage::Blob.service.root.to_s.starts_with?(Rails.public_path.to_s)
    end
  end
end
