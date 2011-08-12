require 'spec_helper'
require 'wulin_master/menu/menu'

describe WulinMaster::Menu do
  before :each do
    @menu = WulinMaster::Menu.new
  end
  
  it "should be a kind of array" do
    @menu.should be_a_kind_of(Array)
  end
  
  it "should render a actionview base object" do
    @menu.render.should be_a_kind_of(ActionView::Base)
  end

end