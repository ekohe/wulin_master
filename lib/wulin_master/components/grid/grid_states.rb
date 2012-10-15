module WulinMaster
  module GridStates
    extend ActiveSupport::Concern
    
    # ----------------------------- Instance Methods ------------------------------------
    def states_for_user(user)
      return "false" if user.nil?
      result = {}
      current_state = GridState.current(user.id, self.name)
      current_state.try(:state_value).presence || "false"
    rescue Exception => e
      Rails.logger.info "Exception thrown while trying to get user states: #{e.inspect}"
      "false"
    end

  end
end

