require 'spec_helper'
require './lib/wulin_master/menu/menu'

# Test MenuEntry
describe WulinMaster::MenuEntry do
  it "should has title and path" do
    pending 'fix'
    @menu_entry = WulinMaster::MenuEntry.new("countries", "/countries")
    @menu_entry.title.should == "countries"
    @menu_entry.path.should == "/countries"
  end
end

# Test Menu
describe WulinMaster::Menu do
  before :each do
    @menu = WulinMaster::Menu.new
  end

  it "should be a kind of array" do
    @menu.should be_a_kind_of(Array)
  end

  it "should render a the right view template" do
    pending('fix')
    WulinMaster.stub_chain(:config, :app_title) { "Undefined App" }
    WulinMaster.stub_chain(:config, :app_title_height) { "40px" }
    sub_menu_1 = WulinMaster::SubMenu.new("sports")
    sub_menu_2 = WulinMaster::SubMenu.new("life")
    @menu << sub_menu_1
    @menu << sub_menu_2

    view = @menu.render
    view.should match(/Undefined App/)
    view.should match(/div id=\"navigation\"/)
    view.should match(/div id=\"activity\"/)
    view.should match(/div id=\"menu\"/)
    view.should match(/li class=\"submenu\"/)
    view.should match(/sports/)
    view.should match(/life/)
  end
end

# Test SubMenu
describe WulinMaster::SubMenu do
  before :each do
    @sub_menu = WulinMaster::SubMenu.new("sports")
  end

  it "should be a kind of Menu" do
    @sub_menu.should be_a_kind_of(WulinMaster::Menu)
  end

  it "should has a title" do
    @sub_menu.title.should == "sports"
  end
end
