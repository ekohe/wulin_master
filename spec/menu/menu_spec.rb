require 'spec_helper'
require 'wulin_master/menu/menu'

# Test MenuEntrt
describe WulinMaster::MenuEntry do
  it "should has title and path" do
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
    menu_view = @menu.render
    menu_view.should match(/navigation/)
    menu_view.should match(/activity/)
    menu_view.should match(/menu/)
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