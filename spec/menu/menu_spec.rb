# frozen_string_literal: true

require "spec_helper"
require "./lib/wulin_master/menu/menu"

# Test MenuEntry
describe WulinMaster::MenuEntry do
  it "should has title and path" do
    @menu_entry = WulinMaster::MenuEntry.new("posts", "/posts", screen_name: "PostScreen")
    expect(@menu_entry.title).to eq("posts")
    expect(@menu_entry.path).to eq("/posts")
    expect(@menu_entry.options).to eq(screen_name: "PostScreen")
  end
end

# Test Menu
describe WulinMaster::Menu do
  before :each do
    @menu = WulinMaster::Menu.new
  end

  it "should be an array" do
    expect(@menu).to be_a Array
  end

  it "should render the view template" do
    sub_menu1 = WulinMaster::SubMenu.new("sports")
    sub_menu2 = WulinMaster::SubMenu.new("life")
    @menu << sub_menu1
    @menu << sub_menu2

    view = @menu.render
    expect(view).to match(/div id='navigation'/)
    expect(view).to match(/div id='menu'/)
    expect(view).to match(/li class='submenu'/)
    expect(view).to match(/sports/)
    expect(view).to match(/life/)
  end
end

# Test SubMenu
describe WulinMaster::SubMenu do
  before :each do
    @sub_menu = WulinMaster::SubMenu.new("sports")
  end

  it "should be a Menu" do
    expect(@sub_menu).to be_a WulinMaster::Menu
  end

  it "should has a title" do
    expect(@sub_menu.title).to eq("sports")
  end
end
