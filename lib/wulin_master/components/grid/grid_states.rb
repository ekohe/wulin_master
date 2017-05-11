module WulinMaster
  module GridStates
    extend ActiveSupport::Concern

    def states_for_user
      return "false" unless current_user
      current_state = GridState.current(current_user.id, name)
      current_state.try(:state_value).presence || {}.to_json
    rescue Exception => e
      Rails.logger.info "Exception thrown while trying to get user states: #{e.inspect}"
      "false"
    end
  end
end
