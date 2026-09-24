# frozen_string_literal: true

require "rails_helper"
require "./app/controllers/wulin_master/grid_states_controller"

class GridStatesImportTestController < WulinMaster::GridStatesController
  skip_before_action :clear_users_cache
  skip_before_action :ensure_users_request_uri
  skip_before_action :require_authorization
end

describe GridStatesImportTestController, type: :controller do
  let(:grid_state) do
    WulinMaster::GridState.create!(
      grid_name: "position",
      name: "default",
      user_id: 1,
      state_value: {columns: [{id: "old", visible: true}]}.to_json
    )
  end

  before do
    routes.draw { post :import_old_format, to: "grid_states_import_test#import_old_format" }
  end

  it "replaces the selected state with the converted value" do
    post :import_old_format, params: {
      id: grid_state.id,
      state_value: {order: {"0" => "name"}, visibility: ["id"]}.to_json
    }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["success"]).to eq(true)
    expect(JSON.parse(grid_state.reload.state_value)).to eq(
      "columns" => [
        {"id" => "name", "visible" => true},
        {"id" => "id", "visible" => false}
      ]
    )
  end

  it "returns the conversion error and leaves the state unchanged" do
    post :import_old_format, params: {id: grid_state.id, state_value: "not json"}

    expect(JSON.parse(response.body)).to eq("success" => false, "message" => "Invalid JSON")
    expect(grid_state.reload.state_value).to include("old")
  end
end
