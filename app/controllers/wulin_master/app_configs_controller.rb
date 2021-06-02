# frozen_string_literal: true

module WulinMaster
  class AppConfigsController < ScreenController
    controller_for_screen AppConfigsScreen

    before_action :load_app_config, only: [:index]

    private

    def load_app_config
      file = Rails.root.join("config/app_config.yml")
      @app_config_content = File.exist?(file) ? File.read(file) : "Can't read #{file}"
    end
  end
end
