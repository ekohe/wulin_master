# frozen_string_literal: true

module WulinMaster
  module GridStates
    extend ActiveSupport::Concern

    def states_for_user
      return "false" unless current_user
      current_state = GridState.current(current_user.id, name)
      if current_state.nil?
        # create a new current grid
        create_current_grid(current_user.id, name)
      else
        current_state.try(:state_value).presence || GridState.get_default_grid(name) || {}.to_json
      end
    rescue StandardError => e
      Rails.logger.info "Exception thrown while trying to get user states: #{e.inspect}"
      "false"
    end

    def create_current_grid(current_user_id, name)
      default = GridState.default_grid(name).first
      current_state = GridState.create(user_id: current_user_id, grid_name: name, state_value: default.try(:state_value).nil? ? {}.to_json : default.state_value, current: true)
      current_state.state_value
    end
  end
end
