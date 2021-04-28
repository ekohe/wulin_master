# frozen_string_literal: true

module WulinMaster
  class RichMediaUploader
    # rubocop:disable Lint/UnusedMethodArgument
    def initialize(file)
      raise(
        NotImplementedError,
        'Implement the method `initialize`. Argument is a `ActionDispatch::Http::UploadedFile`'
      )
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def upload
      raise NotImplementedError, 'Implement the method `upload`. This is where custom upload method is implemented'
    end

    def url
      raise NotImplementedError, 'Implement the method `url`. This will be the `url` of the asset that will be returned upon upload completion.'
    end
  end
end
