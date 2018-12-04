# frozen_string_literal: true

require 'rails_helper'

# Test MenuEntry
describe WulinMaster::GridState do
  context '::create_default' do
    it 'create one if not exist' do
      user_id = 1
      grid_name = 'sonar_next_entity_in_entity'
      grid_state = WulinMaster::GridState.create_default(user_id, grid_name)
      expect(grid_state.class).to eql(WulinMaster::GridState)
    end

    it 'return the first one if exist' do
      user_id = 1
      grid_name = 'sonar_next_entity_in_entity'
      grid_state1 = WulinMaster::GridState.create_default(user_id, grid_name)
      grid_state2 = WulinMaster::GridState.create_default(user_id, grid_name)
      expect(grid_state1).to eql(grid_state2)
    end
  end
end
