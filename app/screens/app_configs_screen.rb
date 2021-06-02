# frozen_string_literal: true

class AppConfigsScreen < WulinMaster::Screen
  title "App Config"

  path "/wulin_master/app_configs"

  panel WulinMaster::AppConfigPanel, width: "100%"
end
