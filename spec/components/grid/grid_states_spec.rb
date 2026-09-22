# frozen_string_literal: true

require "rails_helper"

class StateFallbackGrid < WulinMaster::Grid
  title "People"
  model Person

  column :first_name
  column :last_name

  action :multiple_grid_states, toolbar_item: false
end

class StateFallbackScreen < WulinMaster::Screen
  grid StateFallbackGrid
end

describe WulinMaster::GridStates do
  let(:user) { double(:user, id: 42) }

  let(:grid) do
    controller = double(:controller, params: {}, current_user: user)
    StateFallbackScreen.new(controller).grids.first
  end

  let(:grid_name) { grid.name }

  # The shared state every user of this grid starts from
  let(:initial_state_value) do
    {"columns" => [
      {"id" => "first_name", "visible" => true},
      {"id" => "last_name", "visible" => false}
    ]}.to_json
  end

  before do
    WulinMaster::GridState.create!(user_id: nil, grid_name: grid_name, name: "default",
      state_value: initial_state_value)
  end

  def hidden_columns(states_json)
    columns = JSON.parse(states_json)["columns"] || []
    columns.select { |column| column["visible"] == false }.map { |column| column["id"] }
  end

  context "when the user's current state has a value" do
    before do
      WulinMaster::GridState.create!(user_id: user.id, grid_name: grid_name, name: "My View",
        current: true,
        state_value: {"columns" => [{"id" => "first_name", "visible" => false}]}.to_json)
    end

    it "uses it" do
      expect(hidden_columns(grid.states_for_user)).to contain_exactly("first_name")
    end
  end

  context "when the user's current state has been reset" do
    it "falls back to the initial state for the default view" do
      WulinMaster::GridState.create!(user_id: user.id, grid_name: grid_name, name: "default",
        current: true, state_value: nil)

      expect(hidden_columns(grid.states_for_user)).to contain_exactly("last_name")
    end

    it "falls back to the shared view of the same name when one exists" do
      WulinMaster::GridState.create!(user_id: nil, grid_name: grid_name, name: "IT View",
        state_value: {"columns" => [{"id" => "first_name", "visible" => false}]}.to_json)
      WulinMaster::GridState.create!(user_id: user.id, grid_name: grid_name, name: "IT View",
        current: true, state_value: nil)

      expect(hidden_columns(grid.states_for_user)).to contain_exactly("first_name")
    end

    it "falls back to the initial state for a view the user created themselves" do
      WulinMaster::GridState.create!(user_id: user.id, grid_name: grid_name, name: "My View",
        current: true, state_value: nil)

      expect(hidden_columns(grid.states_for_user)).to contain_exactly("last_name")
    end
  end
end
