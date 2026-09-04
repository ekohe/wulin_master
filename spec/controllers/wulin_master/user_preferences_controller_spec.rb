# frozen_string_literal: true

require "spec_helper"
require "./app/controllers/wulin_master/user_preferences_controller"

class UserPreferencesTestController < WulinMaster::UserPreferencesController
  def current_user
  end
end

describe UserPreferencesTestController, type: :controller do
  let(:user) { double(:user, id: 1) }

  before :each do
    routes.draw do
      get "user_preferences/:name", to: "user_preferences_test#show"
      put "user_preferences/:name", to: "user_preferences_test#update"
      delete "user_preferences/:name", to: "user_preferences_test#destroy"
    end
  end

  context "with a current user" do
    before :each do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it "reads the preference back" do
      WulinMaster::UserPreference.create!(user_id: user.id, name: "pinned_menus", value: %w[/products].to_json)

      get :show, params: {name: "pinned_menus"}

      expect(JSON.parse(response.body)).to eq(["/products"])
    end

    it "stores one under the user" do
      put :update, params: {name: "pinned_menus", value: %w[/products].to_json}

      expect(WulinMaster::UserPreference.find_by(user_id: user.id, name: "pinned_menus").value)
        .to eq(%w[/products].to_json)
    end

    it "removes one" do
      WulinMaster::UserPreference.create!(user_id: user.id, name: "pinned_menus", value: "[]")

      delete :destroy, params: {name: "pinned_menus"}

      expect(WulinMaster::UserPreference.count).to eq(0)
    end
  end

  # An app with no auth gem, asked for its pinned items on every page load.
  context "with no current user" do
    before :each do
      allow(controller).to receive(:current_user).and_return(nil)
    end

    it "reads back no preferences" do
      get :show, params: {name: "pinned_menus"}

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it "refuses to store one, and says why rather than leaking a nil error" do
      put :update, params: {name: "pinned_menus", value: %w[/products].to_json}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to eq("no current user")
      expect(WulinMaster::UserPreference.count).to eq(0)
    end

    it "removes nothing" do
      WulinMaster::UserPreference.create!(user_id: 2, name: "pinned_menus", value: "[]")

      delete :destroy, params: {name: "pinned_menus"}

      expect(response).to have_http_status(:ok)
      expect(WulinMaster::UserPreference.count).to eq(1)
    end
  end
end
