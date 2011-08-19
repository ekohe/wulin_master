require 'spec_helper'

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
  
  it "should assign the title" do
    # default title
    DemoScreen.title.should == "Demo"
    
    # customize title
    DemoScreen.title("Demo Screen")
    DemoScreen.title.should == "Demo Screen"
  end
  
  it "should define a grid in it" do
    # default is empty
    DemoScreen.grids.should == []
    class FirstGrid < WulinMaster::GridConfig
      config do
      end
    end
    
    DemoScreen.grid FirstGrid
    DemoScreen.grids.should == [FirstGrid.grid_context]
  end
end