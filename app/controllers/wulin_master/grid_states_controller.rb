module WulinMaster
  class GridStatesController < ::ActionController::Metal
    def save
      current_state = GridState.current(current_user.id, params[:grid_name])
      current_state.state_value = JSON(current_state.state_value).merge(params[:state_type] => params[:state_value]).to_json
      if current_state.save
        self.response_body = "success"
      else
        self.response_body = current_state.errors.full_messages.join('\n')
      end
    end
    
    def update
      new_state = GridState.find(params[:id])
      GridState.transaction do
        new_state.brother_states.update_all({:current => false})
        new_state.update_attributes!({:current => true})
      end
      self.response_body = "success"
    rescue
      self.response_body = $!.message
    end
  end
end