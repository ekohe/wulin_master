# frozen_string_literal: true

module WulinMaster
  class GridStatesController < ScreenController
    controller_for_screen ::GridStatesScreen

    add_callback :query_initialized, :set_user_ids_for_filtering
    add_callback :query_initialized, :skip_sorting_if_sort_by_user
    add_callback :query_ready, :set_user_ids_for_sorting

    before_action :clear_invalid_states_and_users_cache, only: :index

    def copy
      GridState.transaction do
        params[:user_ids].each do |uid|
          params[:state_ids].each do |sid|
            state = GridState.find(sid)
            next if state.user_id == uid
            new_state = GridState.where(user_id: uid, name: state.name, grid_name: state.grid_name).first
            if new_state
              new_state.update_attributes!(state_value: state.state_value)
            else
              GridState.create!(state.attributes.delete_if { |k, _v| %w[id created_at updated_at].include? k }.merge(user_id: uid))
            end
          end
        end
      end
      render json: {success: true}
    rescue StandardError
      render json: {success: false, error_message: $ERROR_INFO.message}
    end

    protected

    def set_user_ids_for_filtering
      return if params[:filters].blank?

      user_filter = params[:filters].find { |x| x["column"] == "email" }
      return if user_filter.blank?

      user_ids = User.all.select { |u| u.email.include?(user_filter["value"]) }.map(&:id)

      params[:filters].delete user_filter
      @query = @query.where(user_id: user_ids)
    end

    def skip_sorting_if_sort_by_user
      return if params[:sort_col].blank? || (params[:sort_col] != "email")
      @skip_order = true
    end

    def set_user_ids_for_sorting
      return unless @skip_order
      @query = @query.all.sort do |s1, s2|
        return 0 if s1.user.nil? || s2.user.nil?
        params[:sort_dir] == "DESC" ? s2.user.email <=> s1.user.email : s1.user.email <=> s2.user.email
      end
    end

    def clear_invalid_states_and_users_cache
      return unless params[:format] == 'json'
      User.set_request_uri('/users.json?screen=UsersScreen')
      WulinMaster::GridState.all_users = User.all
      WulinMaster::GridState.clear_invalid_states!
    end
  end
end
