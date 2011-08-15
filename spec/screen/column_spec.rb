require 'spec_helper'
require 'wulin_master/screen/column'

describe WulinMaster::Column do

  before :each do
    @mock_grid = mock("grid")
    @column = WulinMaster::Column.new("country_name", @mock_grid)
  end
  
  it "should has a name" do
    @column.name.should == "country_name"
  end
  
  it "should has default options" do
    @column.options.should == {:width => 80, :sortable => true, :editable => true} 
  end
  
  it "can has customized options" do
    @column = WulinMaster::Column.new("country_name", @mock_grid, {:width => 100, :editable => false, :label => "Country Name"})
    @column.options.should == {:width => 100, :sortable => true, :editable => false, :label => "Country Name"}
  end
  
  it "should has a default label" do
    @column.should respond_to(:label)
    @column.label.should == "Country name"
  end
  
  it "can has customized label" do
    @column = WulinMaster::Column.new("country_name", @mock_grid, {:label => "Country Name"})
    @column.label.should == "Country Name" 
  end
  
  it "should respond to to_column_model" do
    @column.should respond_to(:to_column_model)
    @column.should respond_to(:sql_type)
    @column.stub!(:sql_type) { String }
    @column.to_column_model.should == {:id => "country_name", :name => "Country name", :field => "country_name", :type => String, :width => 80, :sortable => true, :editable => true}
  end
  
  it "can apply filter" do
    @column.should respond_to(:apply_filter)
    query = mock("Country")
    @column.apply_filter(query, "").should == query
    
    # filter string type
    @column.stub!(:sql_type) { String }
    sql_result = nil
    query.stub!(:where).with("UPPER(country_name) LIKE UPPER('China%')") { sql_result }
    @column.apply_filter(query, "China").should == sql_result
    
    # filter datetime type
    @column.stub!(:sql_type) { :datetime }
    query.stub!(:where).with("to_char(country_name, 'YYYY-MM-DD') LIKE UPPER('2011-05-03%')") { sql_result }
    @column.apply_filter(query, "2011-05-03").should == sql_result
  end
end