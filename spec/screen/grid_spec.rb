require 'spec_helper'

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
  
  it "should has default toolbar with a filter item, delete item and add item" do
    @grid.toolbar.length.should == 3
    
    item_1 = @grid.toolbar[0]
    item_2 = @grid.toolbar[1]
    item_3 = @grid.toolbar[2]

    item_1.title.should == "Filter"
    item_1.javascript.should == nil
    item_1.icon.should == 'search'
    item_1.options.should == {:class => "filter_toggle", :href => "#"}
    
    item_2.title.should == "Delete"
    item_2.javascript.should == nil
    item_2.icon.should == 'delete_trash'
    item_2.options.should == {:class => "delete_button", :href => "javascript: void(0);"}
    
    item_3.title.should == "Add"
    item_3.javascript.should == nil
    item_3.icon.should == 'create'
    item_3.options.should == {:class => "create_button", :href => "javascript: void(0);"}
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
    
    @grid.toolbar.length.should == 4
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
    @grid.should respond_to(: model)
    @grid.should respond_to(:model)
    # default 
    @grid. model.should == nil
    @grid.model.should == nil
    
    # customize  model
    @grid. model("city")
    @grid. model.should == "city"
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
  
  describe "methods related with columns" do
    before :each do
      @column_1 = WulinMaster::Column.new("name", @grid, {:width => 100, :editable => false, :label => "Country Name"})
      @column_2 = WulinMaster::Column.new("code", @grid, {:width => 200, :editable => true, :label => "Country Code"})
      @grid.columns = [@column_1, @column_2]
    end
    
    it "should get sql_columns" do
      @grid.should respond_to(:sql_columns)
      @grid.sql_columns.should == ["name", "code"]
    end
    
    it "should get sql_select" do
      @grid.should respond_to(:sql_select)
      @grid.sql_select.should == "name,code"
    end
    
    it "should apply filters" do
      @grid.should respond_to(:apply_filter)
      
      @query = mock("query")
      @result_query = mock("result")
      @column_1.stub!(:apply_filter).with(@query, "China").and_return(@result_query)
      
      # filter an existing column
      @grid.apply_filter(@query, "name", "China").should == @result_query
      # filter an non-existing column
      @grid.apply_filter(@query, "money", "China").should == @query
    end

    it "should arraify objects" do
      @grid.should respond_to(:arraify)
      
      @obj_1 = mock("Country")
      @obj_1.stub!(:read_attribute).with("name").and_return("China")
      @obj_1.stub!(:read_attribute).with("code").and_return("CHN")
      
      @obj_2 = mock("Country")
      @obj_2.stub!(:read_attribute).with("name").and_return("United States")
      @obj_2.stub!(:read_attribute).with("code").and_return("USA")
      
      @objects = [@obj_1, @obj_2]
      
      @grid.arraify(@objects).should == [[{"name"=>"China"}, {"code"=>"CHN"}], [{"name"=>"United States"}, {"code"=>"USA"}]]
    end

    it "should get javascript_column_model" do
      @grid.should respond_to(:javascript_column_model)
      
      @attrs_1 = {:id => "name", :name => "Country Name", :field => "name", :type => "String"}
      @attrs_2 = {:id => "code", :name => "Country Code", :field => "code", :type => "String"}
      @column_1.stub!(:to_column_model).and_return(@attrs_1)
      @column_2.stub!(:to_column_model).and_return(@attrs_2)
      
      @grid.javascript_column_model.should == [@attrs_1, @attrs_2].to_json
    end
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