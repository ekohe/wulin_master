# frozen_string_literal: true

module WulinMaster
  class UploadsController < ApplicationController
    # rubocop:disable Metrics/AbcSize
    def create
      # Directly save the upload in a public folder
      #   if we are using disk service in the public folder
      if Object.const_defined?('ActiveStorage::Service::DiskService') &&
         ActiveStorage::Blob.service.root.to_s.starts_with?(Rails.public_path.to_s)

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
      elsif !params[:asset_host].blank?
        # usage of `asset_host` implies the asset need to be public in order to have a permanent url behind the `asset_host`
        raise 'Service is not public. Set `public: true` under the corresponding service under `storage.yml`' unless ActiveStorage::Blob.service.public?

        if params[:asset_host] !~ /^#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}(?<!\/)$/
          raise '`asset_host` is not a valid url. Make sure it contains the protocol and does not end with a forward slash (eg https://www.example.com)'
        end

        # check absence of `//`, leading `/` and trailing `/`
        raise '`blob_key` should not start or end with `/`, or contain `//`' if !params[:blob_key].blank? && params[:blob_key] !~ /^(?!\/)((?!\/\/).)+(?<!\/)$/

        prefix = params[:blob_key].blank? ? '' : "#{params[:blob_key]}/"

        blob = ActiveStorage::Blob.create_and_upload!(
          io: params[:file],
          filename: params[:file].original_filename,
          content_type: params[:file].content_type,
          key: "#{prefix}#{Time.zone.now.to_i}-#{params[:file].original_filename}"
        )
        url = "#{params[:asset_host]}#{URI.parse(blob.url).path}"

        render json: { url: url }
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
  end
end
