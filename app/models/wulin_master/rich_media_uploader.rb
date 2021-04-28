# frozen_string_literal: true

module WulinMaster
  class RichMediaUploader
    # rubocop:disable Lint/UnusedMethodArgument
    def initialize(data)
      raise(
        NotImplementedError,
        'Implement the method `initialize`.' \
        'It should take in 1 argument, which can be anything that is required for your custom implementation to work.' \
        'Eg `Base64` string, `ActionDispatch::Http::UploadedFile` etc.'
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
