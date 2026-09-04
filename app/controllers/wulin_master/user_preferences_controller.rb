# frozen_string_literal: true

module WulinMaster
  class UserPreferencesController < ApplicationController
    # A preference is keyed by user_id, and an app with no auth gem has no current_user: none to
    # read, and nowhere to store one. Storing is refused rather than reported done, because the
    # caller shows the pins it sent as soon as it is told they were saved.
    def show
      return render json: [] unless current_user

      pref = UserPreference.find_by(user_id: current_user.id, name: params[:name])
      render json: pref ? JSON.parse(pref.value) : []
    end

    def update
      return render json: {error: "no current user"}, status: :unprocessable_entity unless current_user

      pref = UserPreference.find_or_initialize_by(user_id: current_user.id, name: params[:name])
      pref.value = params[:value]
      pref.save!
      render json: {success: true}
    rescue StandardError => e
      render json: {error: e.message}, status: :unprocessable_entity
    end

    def destroy
      UserPreference.where(user_id: current_user.id, name: params[:name]).destroy_all if current_user
      render json: {success: true}
    end
  end
end
