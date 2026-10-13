# frozen_string_literal: true

require "rails_helper"

RSpec.describe WulinMaster::ColumnAttr, "a belongs_to column on create" do
  def assigned(country)
    params = ActionController::Parameters.new(screen: "PersonScreen", grid: "PersonGrid", format: :json)
    controller = double("controller", params: params, current_user: nil)
    grid = PersonScreen.new(controller).grids.find { |g| g.instance_of?(PersonGrid) }

    grid.map_attrs(ActionController::Parameters.new(country: country).permit!, :create, Person.new)
  end

  it "takes the id from a request's nested params" do
    expect(assigned({id: "5"})).to include("country_id" => "5")
  end

  it "takes a bare id" do
    expect(assigned("5")).to include("country_id" => "5")
  end
end
