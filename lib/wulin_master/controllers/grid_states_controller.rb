module WulinMaster
  class GridStatesController < ::ApplicationController
    def save
      state_values = params[:state_value].is_a?(Hash) ? params[:state_value].values.to_s : params[:state_value].to_s
      GridState.update_or_create({user_id: current_user.id, 
                                grid_name: params[:grid_name], 
                                state_type: params[:state_type], 
                                state_value: state_values})
      render :nothing => true
    end
  end
end