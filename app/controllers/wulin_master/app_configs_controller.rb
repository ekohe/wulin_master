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

      @rails_version = Rails.version

      # The Gemfile is rewritten on every deploy, so its mtime is when this
      # copy of the app went out. Not every app root has one -- the dummy app
      # the specs boot does not -- so fall back rather than raise.
      gemfile = Rails.root.join("Gemfile")
      @deployed_at = if File.exist?(gemfile)
        File.mtime(gemfile).strftime("%Y-%m-%d %H:%M:%S %Z")
      else
        "unknown"
      end
    end
  end
end
