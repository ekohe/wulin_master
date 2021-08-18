# frozen_string_literal: true

module WulinMaster
  class GridStatesManagesController < ::ActionController::Metal
    include AbstractController::Rendering
    include ActionController::RequestForgeryProtection
    include WulinMasterGridHelper
    include ActionView::Layouts

    append_view_path "#{WulinMaster::Engine.root}/app/views"
    before_action :set_state, only: %i[update destroy set_current]

    def create
      new_state = GridState.new(
        user_id: current_user.id,
        grid_name: params[:grid_name],
        name: params[:state_name],
        current: true
      )
      GridState.transaction do
        new_state.save!
        new_state.brother_states.each do |state|
          state.update!(current: false)
        end
      end
      self.response_body = "success"
    rescue StandardError
      self.response_body = $ERROR_INFO.message
    end

    def save
      current_state = GridState.current_or_default(current_user.id, params[:grid_name])
      state_value = params[:state_value] || { visibility: [] }
      current_state.state_value = JSON.parse(current_state.state_value.presence || GridState.get_default_grid(params[:grid_name]) || "{}").merge(state_value).to_json
      self.response_body = if current_state.save
        {status: "success", data: {id: current_state.id, name: current_state.name}}.to_json
      else
        {status: "failed", data: current_state.errors.full_messages.join('\n')}.to_json
      end
    end

    def update
      @state.update!(name: params[:name])
      self.response_body = "success"
    rescue StandardError
      self.response_body = $ERROR_INFO.message
    end

    def destroy
      @state.destroy
      self.response_body = "success"
    rescue StandardError
      self.response_body = $ERROR_INFO.message
    end

    def set_current
      GridState.transaction do
        @state.brother_states.each do |state|
          state.update!(current: false)
        end
        @state.update!(current: true)
      end
      self.response_body = "success"
    rescue StandardError
      self.response_body = $ERROR_INFO.message
    end

    def batch_update
      params[:grid_states] ||= {}
      all_states = GridState.for_user_and_grid(current_user.id, params[:grid_name])
      default_state = all_states.find_by(name: 'default')
      remaining_ids = params[:grid_states].map { |_index, state| state["id"].presence }.compact.map(&:to_i)

      # delete some states
      GridState.delete(all_states.map(&:id) - remaining_ids - [default_state.id])
      # if only remaining default states, mark it as current
      default_state.update(:current, true)

      GridState.transaction do
        # update or create states
        params[:grid_states].each_value do |state|
          if state[:id].present?
            GridState.find(state[:id]).update!(name: state[:name])
          else
            GridState.create!(name: state[:name], user_id: current_user.id, grid_name: params[:grid_name])
          end
        end
        self.response_body = "success"
      end
    rescue StandardError
      self.response_body = $ERROR_INFO.message
    end

    def reset_default
      name = params[:view_name].blank?? 'default' : params[:view_name]
      if params[:grid_name].present? && params[:user_id].present? && (default = GridState.user_grid_view_name(params[:user_id], params[:grid_name], name).first)
        default.reset!
      end
      render plain: 'ok'
    rescue StandardError
      render plain: $ERROR_INFO.message
    end

    private

    def set_state
      @state = GridState.find(params[:id])
    end
  end
end
