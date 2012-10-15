module WulinMaster
  class GridStatesController < ::ActionController::Metal
    def save
      current_state = GridState.current(current_user.id, params[:grid_name])
      if current_state
        current_state.state_value = JSON(current_state.state_value).merge(params[:state_type] => params[:state_value]).to_json
      else
        current_state = GridState.new(user_id: current_user.id, grid_name: params[:grid_name], 
          name: 'default', current: true, state_value: {params[:state_type] => params[:state_value]}.to_json)
      end
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