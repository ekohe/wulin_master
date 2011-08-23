require 'spec_helper'
require 'wulin_master/controllers/actions'
require 'wulin_master/controllers/screen_controller'

class CountriesController < WulinMaster::ScreenController
  include ActionDispatch::Routing::UrlFor
  attr_accessor :query
end

class Country < ActiveRecord::Base
end

describe CountriesController, :type => :controller do
    
  describe "Includes WulinMaster::Actions" do
    before :each do
      WulinMaster::ScreenController.load_actions
    end
    
    describe "get 'index'" do
      it "should render index template if request format :html" do
        get :index, :format => :html
        response.should render_template(:index)
      end
      
      pending "should render xls if request format :xls" do
        Mime::Type.stub!(:lookup_by_extension).with("xls") { true }
        controller.stub!(:respond_to?).with(:render_xls) { true }
        response.should_receive(:render_xls)
        get :index, :format => :xls
      end
      
      describe "format json" do
        before :each do
          Country.stub!(:count) { 100 }
          Country.stub!(:all) { [] }
          @grid = WulinMaster::Grid.new("country")
          @grid.base_model(Country)
          controller.stub!(:grid) { @grid }
          @mock_model = mock("Country")
          controller.query = @mock_model
        end
        
        it "should invoke methods of building filters, paginations, ordering, selection and fire callbacks" do
          controller.should_receive(:construct_filters)
          controller.should_receive(:parse_pagination)
          controller.should_receive(:parse_ordering)
          controller.should_receive(:add_select)
          controller.should_receive(:render_json)
          controller.should_receive(:fire_callbacks).with(:query_filters_ready)
          controller.should_receive(:fire_callbacks).with(:query_ready)
          get :index, :format => :json
        end
        
        it "should assign Country model to @query, @count, @objects" do
          controller.stub!(:construct_filters) { true }
          controller.stub!(:parse_pagination) { true } 
          controller.stub!(:parse_ordering) { true }
          controller.stub!(:add_select) { true }
          controller.stub!(:render_json) { "" }    
          get :index, :format => :json
          assigns(:query).should == controller.grid.model
          assigns(:count).should == 100
          assigns(:objects).should == []
        end
        
        it "should apply filter on the grid when calling construct_filters" do
          controller.stub!(:params).and_return({:filters => [{:column => "name", :value => "China"}]})
          @grid.should_receive(:apply_filter).with(@mock_model, "name", "China")
          controller.send(:construct_filters)
        end
        
        it "should invoke limit and offset on the query when calling parse_pagination" do
          limited = []
          offseted = []
          controller.stub!(:params).and_return({:count => 100, :offset => 200})
          controller.query.stub!(:limit) { limited }
          limited.stub!(:offset) { offseted }
          controller.query.should_receive(:limit).with(100)
          limited.should_receive(:offset).with(200)
          controller.send(:parse_pagination)
        end
        
        pending "should invoke order on query when calling parse_ordering" do
          #controller.stub!(:params).and_return({})
        end
        
      end
    end
    
    describe "post 'update" do
    end
    
    describe "delete 'destroy" do
    end
  end
  
  describe "Self defined methods" do
    it "should include actions from WulinMaster::Actions" do
      WulinMaster::ScreenController.should_receive(:send).with(:include, WulinMaster::Actions)
      WulinMaster::ScreenController.load_actions
    end
  end
end

  
  

  