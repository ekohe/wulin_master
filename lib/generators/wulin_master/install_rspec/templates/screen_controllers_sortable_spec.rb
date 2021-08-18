# frozen_string_literal: true

require "rails_helper"

IGNORE_SORTABLE_SCREENS = [].freeze

RSpec.describe "Test all grids’ sortable columns", type: :request do
  let(:admin_user) do
    double :user,
      admin?: true,
      has_permission_with_name?: true,
      email: "#{SecureRandom.hex}@example.com",
      level: 1,
      id: 0
  end

  let(:screens) do
    WulinMaster::Screen.screens
  end

  let(:grid_pairs) do
    screens.each_with_object({}) do |screen, target|
      next unless screen.components_pool
      next if IGNORE_SORTABLE_SCREENS.include? screen

      grids = screen.components_pool.reject { |item| item.to_s =~ /panel/i }

      grids.each do |grid|
        target[grid] = screen
      end
    end
  end

  before :all do
    Rails.application.eager_load!
  end

  before :each do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin_user)
  end

  it "success sort all columns for all grids" do
    grid_pairs.each_pair do |grid, screen|
      url = grid.path + ".json"

      columns = grid.columns_pool.map do |item|
        case item.options["sortable"]
        when true, nil
          item.name
        end
      end.compact

      columns.each do |col|
        params = {
          grid: grid.to_s,
          screen: screen.to_s,
          xhr: 1,
          offset: 0,
          count: 200,
          sort_col: col,
          sort_dir: %w[ASC DESC],
          columns: columns.join(",")
        }

        get url, params: params, xhr: 1

        json = JSON.parse response.body
        expect(response).to have_http_status(:ok)
        expect(json.key?("rows")).to be_truthy
      end
    end
  end
end
