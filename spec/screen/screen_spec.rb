require 'spec_helper'
require './lib/wulin_master/screen/screen'

describe WulinMaster::Screen do
  before :each do
    Rails.stub_chain(:logger, :info) { "" }
    # define DemoScreen
    class DemoScreen < WulinMaster::Screen
    end
  end

  it "should push an inherited screen into class variable screens" do
    WulinMaster::Screen.screens.should == [DemoScreen]
  end

  it "should has the default title" do
    DemoScreen.title.should == "Demo"
  end

  it "should assign the title" do
    # customize title
    DemoScreen.title("Demo Screen")
    DemoScreen.title.should == "Demo Screen"
  end

  it "should has the default path" do
    pending 'fix'
    DemoScreen.path.should == "/demos"
  end

  it "should assign the path" do
    # customize path
    DemoScreen.path("/demo_screens")
    DemoScreen.path.should == "/demo_screens"
  end

  it "should define a grid in it" do
    # default is empty
    pending 'fix'
    DemoScreen.grids.should == []
    class FirstGrid < WulinMaster::GridConfig
      config do
      end
    end

    DemoScreen.grid FirstGrid
    DemoScreen.grids.should == [FirstGrid.grid_context]
  end
end
