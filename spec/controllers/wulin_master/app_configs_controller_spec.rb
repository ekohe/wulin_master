# frozen_string_literal: true

require "spec_helper"
require "./app/screens/app_configs_screen"
require "./app/controllers/wulin_master/app_configs_controller"

class AppConfigsTestController < WulinMaster::AppConfigsController; end

describe AppConfigsTestController, type: :controller do
  describe "#load_app_config" do
    context "when APP_CONFIG is defined" do
      before do
        stub_const("APP_CONFIG", {"wulin_master" => {"app_title" => "Olatu"}, "time_zone" => "UTC"})
      end

      it "renders the live APP_CONFIG as YAML" do
        controller.send(:load_app_config)
        expect(controller.instance_variable_get(:@app_config_content)).to eq(APP_CONFIG.to_hash.to_yaml)
      end

      it "includes merged keys, not just config/app_config.yml on disk" do
        controller.send(:load_app_config)
        yaml = controller.instance_variable_get(:@app_config_content)
        expect(YAML.safe_load(yaml)).to eq("wulin_master" => {"app_title" => "Olatu"}, "time_zone" => "UTC")
      end
    end

    context "when APP_CONFIG is not defined" do
      before { hide_const("APP_CONFIG") if defined?(APP_CONFIG) }

      it "reports the missing constant instead of crashing" do
        controller.send(:load_app_config)
        expect(controller.instance_variable_get(:@app_config_content)).to eq("APP_CONFIG is not defined")
      end
    end
  end
end
