# frozen_string_literal: true

module WulinMaster
  class UserPreferencesController < ApplicationController
    include WulinMaster::HostUser

    # Three answers, not one: storing is refused rather than reported done, because the caller
    # applies the pins as soon as it is told they were saved and they would vanish on the next page
    # load. Removing reports done -- there is nothing keyed to a missing user to remove.
    def show
      return render json: [] unless current_user?

      pref = UserPreference.find_by(user_id: current_user.id, name: params[:name])
      render json: pref ? JSON.parse(pref.value) : []
    end

    def update
      return render json: {error: "no current user"}, status: :unprocessable_content unless current_user?

      pref = UserPreference.find_or_initialize_by(user_id: current_user.id, name: params[:name])
      pref.value = params[:value]
      pref.save!
      render json: {success: true}
    rescue StandardError => e
      render json: {error: e.message}, status: :unprocessable_content
    end

    def destroy
      UserPreference.where(user_id: current_user.id, name: params[:name]).destroy_all if current_user?
      render json: {success: true}
    end
  end
end
