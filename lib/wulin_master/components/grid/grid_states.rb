# frozen_string_literal: true

module WulinMaster
  module GridStates
    extend ActiveSupport::Concern

    def states_for_user
      return "false" unless current_user
      current_state = GridState.current(current_user.id, name)
      is_custom_view = check_multiple_grid_states
      if current_state.nil?
        # create a new current grid
        create_current_grid(current_user.id, name)
      else
        current_state.try(:state_value).presence || GridState.get_default_grid_state_val(name, current_state.name, is_custom_view ) || {}.to_json
      end
    rescue StandardError => e
      Rails.logger.info "Exception thrown while trying to get user states: #{e.inspect}"
      "false"
    end

    def create_current_grid(current_user_id, name)
      default_state_value = GridState.get_default_grid_state_val(name)
      state_val = default_state_value ? default_state_value : {}.to_json
      current_state = GridState.find_or_initialize_by(user_id: current_user_id, grid_name: name, state_value: state_val)
      current_state.update(current: true)
      current_state.state_value
    end

    private

    def check_multiple_grid_states
      self.actions.any? { |action| action[:name] == :multiple_grid_states }
    end

  end
end
