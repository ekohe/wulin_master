# frozen_string_literal: true

module WulinMaster
  class RichMediaUploader
    attr_reader :file

    def initialize(file)
      raise 'Argument should be a ActionDispatch::Http::UploadedFile type' unless file.is_a?(ActionDispatch::Http::UploadedFile)

      @file = file
    end

    def upload
      raise NotImplementedError, 'Implement the method `upload`. This is where custom upload method is implemented'
    end

    def url
      raise NotImplementedError, 'Implement the method `url`. This will be the `url` of the asset that will be returned upon upload completion.'
    end
  end
end
