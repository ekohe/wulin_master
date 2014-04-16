module WulinMaster
  class GridStatesController < ScreenController
    controller_for_screen ::GridStatesScreen

    def copy
      GridState.transaction do
        params[:user_ids].each_with_index do |uid, index|
          params[:state_ids].each do |sid|
            state = GridState.find(sid)
            next if state.user_id == uid
            new_state = GridState.where(user_id: uid, name: state.name, grid_name: state.grid_name).first
            if new_state
              new_state.update_attributes!({state_value: state.state_value})
            else
              GridState.create!(state.attributes.delete_if{|k,v| ["id", "created_at", "updated_at"].include? k}.merge(user_id: uid, user_email: params[:user_emails]["#{index}"]["email"]))
            end
          end
        end
      end
      render :json => {success: true}
    rescue
      render :json => {success: false, error_message: $!.message}
    end

    protected
    # Disabled - too dangerous
    def clear_invalid_states_and_users_cache
      if params[:format] == 'json'
        User.set_request_uri('/users.json?screen=UsersScreen')
        WulinMaster::GridState.all_users = User.all
        WulinMaster::GridState.clear_invalid_states!
      end
    end

  end
end
