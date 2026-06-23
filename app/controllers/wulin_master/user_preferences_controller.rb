# frozen_string_literal: true

module WulinMaster
  class UserPreferencesController < ApplicationController
    def show
      pref = UserPreference.find_by(user_id: current_user.id, name: params[:name])
      render json: pref ? JSON.parse(pref.value) : []
    end

    def update
      pref = UserPreference.find_or_initialize_by(user_id: current_user.id, name: params[:name])
      pref.value = params[:value]
      pref.save!
      render json: {success: true}
    rescue StandardError => e
      render json: {error: e.message}, status: :unprocessable_entity
    end

    def destroy
      UserPreference.where(user_id: current_user.id, name: params[:name]).destroy_all
      render json: {success: true}
    end
  end
end
