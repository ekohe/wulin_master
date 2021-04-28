# frozen_string_literal: true

module WulinMaster
  class RichMediaUploader
    # rubocop:disable Lint/UnusedMethodArgument
    def initialize(file)
      raise NotImplementedError, 'Implement the method `initialize`.'
    end
    # rubocop:enable Lint/UnusedMethodArgument

    def upload
      raise NotImplementedError, 'Implement the method `upload`.'
    end

    def url
      raise NotImplementedError, 'Implement the method `url`.'
    end
  end
end
