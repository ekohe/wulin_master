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

  describe "#reset_default" do
    let(:state_value) { {columns: [{id: "name", visible: true}]}.to_json }

    before :each do
      allow(controller).to receive(:current_user).and_return(user)
      routes.draw { put :reset_default, to: "grid_states_manages_test#reset_default" }
    end

    def create_state(name, current)
      WulinMaster::GridState.create!(
        grid_name: grid_name, name: name, user_id: user.id, current: current, state_value: state_value
      )
    end

    it "resets the view the user is currently on" do
      default_state = create_state("default", false)
      current_state = create_state("custom", true)

      put :reset_default, params: {grid_name: grid_name}

      expect(current_state.reload.state_value).to be_nil
      expect(default_state.reload.state_value).to eq(state_value)
    end

    it "leaves the states of another grid alone" do
      other_state = WulinMaster::GridState.create!(
        grid_name: "other_grid", name: "default", user_id: user.id, current: true, state_value: state_value
      )
      create_state("default", true)

      put :reset_default, params: {grid_name: grid_name}

      expect(other_state.reload.state_value).to eq(state_value)
    end

    it "answers ok when the user has no state for the grid" do
      put :reset_default, params: {grid_name: grid_name}

      expect(response.body).to eq("ok")
    end
  end
end
