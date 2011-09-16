module WulinMaster
  class GridStatesController < ::ApplicationController
    
    def save
      GridState.update_or_create({ user_id: current_user.id, 
                                   grid_name: params[:grid_name], 
                                   state_type: params[:state_type], 
                                   state_value: params[:state_value].to_json })
      render :nothing => true
    end
    
  end
end