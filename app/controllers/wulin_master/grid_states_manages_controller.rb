# frozen_string_literal: true

module WulinMaster
  # Inherits the host's ApplicationController, like every other controller in
  # this engine. It subclassed ActionController::Metal from 2012 until now, but
  # every action here calls current_user, and Metal never had it: hosts get
  # current_user from an auth layer that patches ActionController::Base
  # (wulin_oauth does `::ActionController::Base.send :include,
  # WulinOAuth::Controller`), which a Metal subclass does not inherit. So every
  # save raised NameError: undefined local variable or method `current_user'.
  class GridStatesManagesController < ApplicationController
    include WulinMasterGridHelper

    append_view_path "#{WulinMaster::Engine.root}/app/views"
    before_action :require_current_user
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
      state_value = parsed_state_value
      default_grid_state_val = GridState.get_default_grid_state_val(params[:grid_name])
      current_state.state_value = JSON.parse(current_state.state_value.presence || default_grid_state_val || "{}").merge(state_value).to_json
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
      GridState.current(current_user.id, params[:grid_name])&.reset!
      render plain: 'ok'
    rescue StandardError
      render plain: $ERROR_INFO.message
    end

    private

    # Every state is keyed by user_id, and an app with no auth gem has no current_user. The grid
    # renders without a state either way -- GridStates#states_for_user returns "false".
    def require_current_user
      self.response_body = "no current user" unless current_user
    end

    def set_state
      @state = GridState.find(params[:id])
    end

    # The grid posts state either as a JSON string or as nested params. Now that
    # this controller is an ActionController::Base, nested params arrive as
    # ActionController::Parameters, which Hash#merge refuses with
    # UnfilteredParameters -- under ActionController::Metal they were a plain
    # Hash. to_unsafe_h is fine here: the result is serialised to a JSON column,
    # never mass-assigned.
    def parsed_state_value
      case (raw = params[:state_value])
      when String then JSON.parse(raw)
      when ActionController::Parameters then raw.to_unsafe_h
      when nil then {visibility: []}
      else raw
      end
    end
  end
end
