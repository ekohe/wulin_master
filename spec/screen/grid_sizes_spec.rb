# frozen_string_literal: true

require "spec_helper"

# PostGrid is on PersonScreen (side by side, 50% wide) and on AnotherPersonScreen (stacked, 30% high)
describe "Grid sizes dragged on a screen" do
  let(:user) { Struct.new(:id).new(1) }
  let(:host_controller) { Struct.new(:params, :current_user) }

  def screen_for(screen_class, current_user)
    params = ActionController::Parameters.new(screen: screen_class.name, format: "json")
    screen_class.new(host_controller.new(params, current_user))
  end

  def grid_style(screen_class, grid_class, current_user)
    screen_for(screen_class, current_user).grids.find { |grid| grid.instance_of?(grid_class) }.style
  end

  def save_sizes(user_id, screen_class, sizes)
    WulinMaster::UserPreference.create!(user_id: user_id, name: screen_class.name, value: sizes.to_json)
  end

  it "uses the screen size when nothing is saved" do
    expect(grid_style(PersonScreen, PersonGrid, user)).to include("width: 50%;")
  end

  it "uses the saved size of each grid on the screen" do
    save_sizes(user.id, PersonScreen, "PersonGrid" => {"width" => "35%"}, "PostGrid" => {"width" => "65%"})

    expect(grid_style(PersonScreen, PersonGrid, user)).to include("width: 35%;").and include("height: 100%;")
    expect(grid_style(PersonScreen, PersonGrid, user)).not_to include("width: 50%;")
    expect(grid_style(PersonScreen, PostGrid, user)).to include("width: 65%;")
  end

  it "keeps the size of a shared grid on its other screens" do
    save_sizes(user.id, PersonScreen, "PostGrid" => {"width" => "65%"})

    expect(grid_style(AnotherPersonScreen, PostGrid, user)).to include("height: 30%;").and include("width: 100%;")
  end

  it "does not use the sizes of another user" do
    save_sizes(user.id + 1, PersonScreen, "PersonGrid" => {"width" => "35%"})

    expect(grid_style(PersonScreen, PersonGrid, user)).to include("width: 50%;")
  end

  it "uses the screen size without a signed-in user" do
    expect(grid_style(PersonScreen, PersonGrid, nil)).to include("width: 50%;")
  end

  it "gives each grid the default minimum size" do
    grid = screen_for(PersonScreen, user).grids.find { |grid| grid.instance_of?(PersonGrid) }

    expect(grid.custom_config).to include(min_width: 300, min_height: 200)
  end

  it "uses the minimum size set on the screen" do
    grid = screen_for(PersonScreen, user).grids.find { |grid| grid.instance_of?(PostGrid) }

    expect(grid.custom_config).to include(min_width: 400, min_height: 200)
  end

  it "is resizable unless the screen turns it off" do
    expect(PersonScreen.resizable).to be(true)
    expect(FixedPersonScreen.resizable).to be(false)
  end

  it "ignores saved sizes on a screen that is not resizable" do
    save_sizes(user.id, FixedPersonScreen, "PersonGrid" => {"width" => "35%"})

    expect(grid_style(FixedPersonScreen, PersonGrid, user)).to include("width: 50%;")
  end

  it "keeps a static size on a panel" do
    panel = screen_for(AnotherPersonScreen, user).panels.first

    expect(panel.style).to include("height: 40%;")
  end
end
