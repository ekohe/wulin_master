# frozen_string_literal: true

require "yaml"

module WulinMaster
  class AppConfigsController < ScreenController
    controller_for_screen AppConfigsScreen

    before_action :load_app_config, only: [:index]

    private

    def load_app_config
      @app_config_content = if defined?(::APP_CONFIG)
        ::APP_CONFIG.to_hash.to_yaml
      else
        "APP_CONFIG is not defined"
      end
    end
  end
end
