require "spec_helper"

describe WulinMaster::GridConfig do

  it "should assign grid name after definition" do
    class TestGrid < WulinMaster::GridConfig
    end
    TestGrid.grid_name.should == "test"
  end
  
  it "should assign grid contenxt after config" do
    class TestGrid < WulinMaster::GridConfig
      config do
      end
    end
    TestGrid.grid_context.should_not be_nil
    TestGrid.grid_context.name.should == :test
  end
  
  it "should be able to configure " do
  end
end