require 'spec_helper'
require 'wulin_master/screen/grid'
require 'wulin_master/screen/column'

describe WulinMaster::Grid do
  before :each do
    @grid = WulinMaster::Grid.new("country")
  end
  
  it "should has a name" do
    @grid.name.should == "country"
  end
  
  it "should has default columns" do
    column = @grid.columns.first
    
    @grid.columns.length.should == 1
    column.name.should == :id
    column.options.should == {:width => 80, :visible => false, :editable => false, :sortable => true}
  end
  
  it "should has default toolbar with a filter item" do
    item = @grid.toolbar.first
    
    @grid.toolbar.length.should == 1
    item.title.should == "Filter"
    item.javascript.should == nil
    item.icon.should == 'search'
    item.options.should == {:class => "filter_toggle", :href => "#"}
  end
  
  it "can add customized columns" do
    @grid.column("currency", {:width => 100, :editable => true})
    new_column = @grid.columns.last
    
    @grid.columns.length.should == 2
    new_column.name.should == "currency"
    new_column.options.should == {:width => 100, :editable => true, :sortable => true}
  end
  
  it "can add customized toolbar items" do
    @grid.add_to_toolbar("Excel", {:class => "excel_toggle", :javascript => "alert('excel')", :icon => "excel", :href => "/export_excel"})
    new_item = @grid.toolbar.last
    
    @grid.toolbar.length.should == 2
    new_item.title.should == "Excel"
    new_item.javascript.should == "alert('excel')"
    new_item.icon.should == "excel"
    new_item.options.should == {:class => "excel_toggle", :href => "/export_excel"}
  end
  
  it "can contruct a json format column_model for all column" do
    @grid.should respond_to(:javascript_column_model)
    
    column = mock("Column")
    options = {:id => "country_name", :name => "Country name", :field => "country_name", :type => String, :width => 80, :sortable => true, :editable => true}
    column.stub!(:to_column_model).and_return(options)
    @grid.stub!(:columns).and_return([column])
    
    @grid.javascript_column_model.should == [options].to_json
  end
  
  it "should control itself to be fill window" do
    @grid.should respond_to(:fill_window)
    @grid.fill_window?.should == false
    
    @grid.fill_window
    @grid.fill_window?.should == true
  end
  
  it "should control the width and height by the given params" do
    @grid.should respond_to(:width)
    @grid.should respond_to(:height)
    # default size
    @grid.width.should == 800
    @grid.height.should == 400
    
    # customize size
    @grid.width(500)
    @grid.height(700)
    @grid.width.should == 500
    @grid.height.should == 700
  end
  
  it "should assign a title to grid" do
    @grid.should respond_to(:title)
    # default title
    @grid.title.should == "Country"
    
    # customize title
    @grid.title("All Countries")
    @grid.title.should == "All Countries"
  end
  
  it "should assign a base model to grid" do
    @grid.should respond_to(:base_model)
    @grid.should respond_to(:model)
    # default 
    @grid.base_model.should == nil
    @grid.model.should == nil
    
    # customize base_model
    @grid.base_model("city")
    @grid.base_model.should == "city"
    @grid.model.should == "city"
  end
  
  it "should assign a load path to grid" do
    @grid.should respond_to(:path)
    # default
    @grid.path.should == nil
    
    # customize path
    @grid.path("/countries")
    @grid.path.should == "/countries"
  end
  
  it "should return stylesheet for the grid body" do
    @grid.should respond_to(:style_for_grid)
    
    # given width and height
    @grid.width(500)
    @grid.height(800)
    @grid.style_for_grid.should == "height: 800px; width: 500px;"
    
    # fill window
    @grid.fill_window
    @grid.style_for_grid.should == "position: absolute; top:59px; left:0; right:0; bottom:26px;"
  end
  
  it "should return stylesheet for the grid header" do
    @grid.should respond_to(:style_for_header)
    
    # given width and height
    @grid.width(500)
    @grid.height(800)
    @grid.style_for_header.should == "width: 500px"
    
    # fill window
    @grid.fill_window
    @grid.style_for_header.should == "position: absolute; top:0; left:0; right:0;"
  end
  
  it "should return stylesheet for the grid pager" do
    @grid.should respond_to(:style_for_pager)
    
    # given width and height
    @grid.width(500)
    @grid.height(800)
    @grid.style_for_pager.should == "width: 500px"
    
    # fill window
    @grid.fill_window
    @grid.style_for_pager.should == "position: absolute; left:0; right:0; bottom:0;"
  end
  
  it "should render grid template" do
    @grid.stub!(:style_for_header) { 'header_style' }
    @grid.stub!(:style_for_grid) { 'grid_style' }
    @grid.stub!(:style_for_pager) { 'pager_style' }
    @grid.stub!(:name) { 'country' }
    @grid.stub!(:path) { '/countries' }
    @grid.stub!(:javascript_column_model).and_return([{:id => "id", :width => 80}].to_json)
    view = @grid.render
    
    
    view.should match(/<div id='grid_country' class='grid_container'>/)
    view.should include("<div class='grid-header' style='header_style'>")
    view.should match(/<h2>Country<\/h2>/)
    view.should include("<div class='grid' style='grid_style'>")
    view.should include("<div class='pager' style='pager_style'>")
    view.should include("<script type='text/javascript'>")
    view.should include("gridManager.createNewGrid('country', \"/countries\", [{\"id\":\"id\",\"width\":80}])")
  end
  
end