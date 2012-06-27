module WulinMaster
  class GridStatesController < ::ActionController::Metal
    
    def save
      GridState.update_or_create({ user_id: current_user.id, 
                                   grid_name: params[:grid_name], 
                                   state_type: params[:state_type], 
                                   state_value: params[:state_value].to_json })
      self.response_body = "success"
    end
    
  end
end