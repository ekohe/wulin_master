# frozen_string_literal: true

module WulinMaster
  class GridStatesController < ScreenController
    controller_for_screen ::GridStatesScreen

    add_callback :query_initialized, :set_user_ids_for_filtering
    add_callback :query_initialized, :skip_sorting_if_sort_by_user
    add_callback :query_ready, :set_user_ids_for_sorting
    add_callback :query_ready, :filter_default_grids

    def copy
      GridState.transaction do
        params[:user_ids].each do |uid|
          params[:state_ids].each do |sid|
            state = GridState.find(sid)
            next if state.user_id == uid
            new_state = GridState.where(user_id: uid, name: state.name, grid_name: state.grid_name).first
            if new_state
              new_state.update!(state_value: state.state_value)
            else
              GridState.create!(state.attributes.delete_if { |k, _v| %w[id created_at updated_at].include? k }.merge(user_id: uid))
            end
          end
        end
      end
      render json: {success: true}
    rescue
      render json: {success: false, error_message: $ERROR_INFO.message}
    end

    def set_as_initial
      return unless params[:id]
      grid = GridState.find(params[:id])
      # case when selected grid is an default grid
      render json: {success: false, message: "Selected Grid is already set to default"} and return if grid.user_id.nil?
      # search for it's default grid state or initialize one
      default_grid = GridState.where(name: grid.name, grid_name: grid.grid_name, user_id: nil).first_or_initialize
      default_grid.state_value = grid.state_value
      default_grid.save
      render json: {success: true, response: true }
    rescue => e
      ExceptionNotifier.notify_exception e
      render json: {success: false, message: "We're sorry, something went wrong."}
    end

    protected

    def set_user_ids_for_filtering
      return if params[:filters].blank?

      user_filter = params[:filters].find { |x| x["column"] == "email" }
      return if user_filter.blank?

      user_ids = cached_all_user.select { |u| u.email.include?(user_filter["value"]) }.map(&:id)

      params[:filters].delete user_filter
      @query = @query.where(user_id: user_ids)
    end

    def cached_all_user
      @cached_all_user ||= User.all
    end

    def skip_sorting_if_sort_by_user
      return if params[:sort_col].blank? || (params[:sort_col] != "email")
      @skip_order = true
    end

    def set_user_ids_for_sorting
      return unless @skip_order

      direction = case params[:sort_dir]
      when /desc/i
        :desc
      when /asc/i
        :asc
      end

      return unless direction

      temporary_sorting = cached_all_user.map do |user|
        "(#{user.id}, '#{user.email}')"
      end.join(",")

      @query = @query.joins("LEFT JOIN (VALUES #{temporary_sorting}) AS temporary_sorting(temp_user_id, temp_email) ON temporary_sorting.temp_user_id = grid_states.user_id").order("temporary_sorting.temp_email" => direction)
    end

    def filter_default_grids
      @query = if params[:default_grids].present?
        @query.where(user_id: nil)
      else
        @query.where("user_id IS NOT NULL")
      end
    end
  end
end
