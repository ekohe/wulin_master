# frozen_string_literal: true

require "spec_helper"
require "./app/controllers/wulin_master/grid_states_manages_controller"

class GridStatesManagesTestController < WulinMaster::GridStatesManagesController
  def current_user
  end
end

describe GridStatesManagesTestController, type: :controller do
  let(:grid_name) { "grid_name" }
  let(:user) { double(:user, id: 1) }

  describe "#save" do
    before :each do
      allow(controller).to receive(:current_user).and_return(user)
      routes.draw { post :save, to: "grid_states_manages_test#save" }
    end

    it "saves grid_state when single state_value" do
      grid_state = WulinMaster::GridState.create(grid_name: grid_name, name: "default", user_id: user.id)

      post :save, params: {
        grid_name: grid_name,
        state_value: {order: {0 => "name"}}
      }

      expect(grid_state.reload.state_value).to eq({order: {0 => "name"}}.to_json)
    end

    it "saves grid_state when multiple state_values" do
      grid_state = WulinMaster::GridState.create(grid_name: grid_name, name: "default", user_id: user.id)

      post :save, params: {
        grid_name: grid_name,
        state_value: {order: {0 => "name"}, visibility: ["id"]}
      }

      expect(grid_state.reload.state_value).to eq({order: {0 => "name"}, visibility: ["id"]}.to_json)
    end

    it "creates grid_state if there is no grid_state" do
      post :save, params: {
        grid_name: grid_name,
        state_value: {order: {0 => "name"}, visibility: ["id"]}
      }

      grid_state = WulinMaster::GridState.find_by(grid_name: grid_name, name: "default", user_id: user.id)
      expect(grid_state.state_value).to eq({order: {0 => "name"}, visibility: ["id"]}.to_json)
    end
  end
end
