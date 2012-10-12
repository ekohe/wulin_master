module WulinMaster
  module GridStates
    extend ActiveSupport::Concern
    
    # ----------------------------- Instance Methods ------------------------------------
    def states_for_user(user)
      return "false" if user.nil?
      result = {}
      begin
        current_state = GridState.current(user.id, self.name)
        current_state.state_value
      rescue Exception => e
        Rails.logger.info "Exception thrown while trying to get user states: #{e.inspect}"
        {}.to_json
      end
    end

  end
end

