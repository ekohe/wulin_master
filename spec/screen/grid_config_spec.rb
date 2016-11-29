require "rails_helper"

describe 'WulinMaster::GridConfig' do

  it "should assign grid name after definition" do
    pending 'fix'
    class TestGrid < WulinMaster::GridConfig
    end
    TestGrid.grid_name.should == "test"
  end

  it "should assign grid contenxt after config" do
    pending 'fix'
    class TestGrid < WulinMaster::GridConfig
      config do
      end
    end
    TestGrid.grid_context.should_not be_nil
    TestGrid.grid_context.name.should == :test
  end

  it "should invoke methods on grid_context" do
    pending 'fix'
    class TestModel
    end

    TestGrid.grid_context.should_receive(:send).with(:title, "Test Grid")
    TestGrid.title "Test Grid"

    TestGrid.grid_context.should_receive(:send).with(:model, TestModel)
    TestGrid. model TestModel

    TestGrid.grid_context.should_receive(:send).with(:path, "/tests")
    TestGrid.path "/tests"

    TestGrid.grid_context.should_receive(:send).with(:fill_window)
    TestGrid.fill_window

    TestGrid.grid_context.should_receive(:send).with(:width, 300)
    TestGrid.grid_context.should_receive(:send).with(:height, 400)
    TestGrid.width 300
    TestGrid.height 400

    TestGrid.grid_context.should_receive(:send).with(:column, :code, :editable => false)
    TestGrid.column :code, :editable => false
  end
end
