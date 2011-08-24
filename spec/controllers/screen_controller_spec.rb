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
  
  def mock_country(stubs={})
    @mock_country ||= mock_model(Country, stubs).as_null_object
  end
  
  describe "Includes WulinMaster::Actions" do
    before :each do
      WulinMaster::ScreenController.load_actions
      @grid = WulinMaster::Grid.new("country")
      @grid.base_model(Country)
      @grid.stub!(:model) { Country }
      controller.stub!(:grid) { @grid }
    end
    
    describe "get 'index'" do
      it "should render index template if request format :html" do
        get :index, :format => :html
        response.should render_template(:index)
      end
      
      describe "format json" do
        before :each do
          Country.stub!(:count) { 100 }
          Country.stub!(:all) { [] }
          @mock_model = mock("Country")
          controller.query = @mock_model
        end
        
        it "should invoke methods of building filters, paginations, ordering, selection and fire callbacks" do 
          @query_origin = mock("query")
          @grid.should_receive(:model).and_return(@query_origin)
          controller.should_receive(:construct_filters)
          controller.should_receive(:parse_pagination)
          controller.should_receive(:parse_ordering)
          controller.should_receive(:add_select)
          controller.should_receive(:render_json)
          controller.should_receive(:fire_callbacks).with(:query_filters_ready)
          controller.should_receive(:fire_callbacks).with(:query_ready)
          @query_origin.should_receive(:count)
          @query_origin.should_receive(:all)
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
        
        it "should render json object as the response" do
          @json_obj = {:offset => 100, :total => 1000, :count => 100, :rows => ["China", "USA"]}.to_json
          controller.stub!(:construct_filters) { true }
          controller.stub!(:parse_pagination) { true } 
          controller.stub!(:parse_ordering) { true }
          controller.stub!(:add_select) { true }
          controller.stub!(:render_json) {@json_obj}
          get :index, :format => :json
          response.body.should == @json_obj
        end
        
        it "should apply filter on the grid when calling construct_filters if given filter params" do
          controller.stub!(:params).and_return({:filters => [{:column => "name", :value => "China"}]})
          @grid.should_receive(:apply_filter).with(@mock_model, "name", "China")
          controller.send(:construct_filters)
        end
        
        it "should do nothing when calling construct_filters if no filter params given" do
          controller.stub!(:params).and_return({})
          @grid.should_not_receive(:apply_filter)
          controller.send(:construct_filters)
        end
        
        it "should invoke limit and offset on the query according to params count and offset when calling parse_pagination if params given" do
          limited = []
          offseted = []
          controller.stub!(:params).and_return({:count => 100, :offset => 200})
          controller.query.stub!(:limit) { limited }
          limited.stub!(:offset) { offseted }
          controller.query.should_receive(:limit).with(100)
          limited.should_receive(:offset).with(200)
          controller.send(:parse_pagination)
        end
        
        it "should invoke limit and offset on the query with default value when calling parse_pagination if params not given " do
          limited = []
          offseted = [] 
          controller.stub!(:params).and_return({})
          controller.query.stub!(:limit) { limited }
          limited.stub!(:offset) { offseted }
          controller.query.should_receive(:limit).with(200)
          limited.should_receive(:offset).with(0)
          controller.send(:parse_pagination)
        end
        
        it "should invoke order on query when calling parse_ordering if params given" do
          @grid.stub!(:sql_columns) { ["name", "code"] }
          controller.stub!(:params).and_return({:sort_col => "code", :sort_dir => "DESC"})
          controller.query.should_receive(:order).with("code DESC")
          controller.send(:parse_ordering)
        end
        
        it "should invoke order on query with default value when calling parse_ordering if params not given" do
          @grid.stub!(:sql_columns) { ["name", "code"] }
          controller.stub!(:params).and_return({})
          controller.query.should_receive(:order).with("name ASC")
          controller.send(:parse_ordering)
        end
        
        it "should invoke select on query when calling add_select" do
          @grid.stub!(:sql_select) { "sql_select" }
          controller.query.should_receive(:select).with("sql_select")
          controller.send(:add_select)
        end
        
        it "should return a json object after calling render_json" do
          @grid.stub!(:arraify) { ["China", "USA"] }
          @grid.should_receive(:arraify)
          result = controller.send(:render_json)
          result.should be_a_kind_of(String)
          result.should include("offset")
          result.should include("total")
          result.should include("count")
          result.should include("rows")
          result.should include("[\"China\",\"USA\"]")
        end
      end
    end
    
    describe "post 'create'" do
      describe "with valid params" do
        it "assigns a newly created record as @record" do
          @grid.model.stub(:new).with({'these' => 'params'}) { mock_country(:save => true) }
          post :create, :country => {'these' => 'params'}
          assigns(:record).should be(mock_country)
        end
        
        it "render success json if format json" do
          @grid.model.stub(:new) { mock_country(:save => true) }
          post :create, :country => {}, :format => :json
          response.body.should == {:success => true}.to_json 
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved record as @record" do
          @grid.model.stub(:new).with({'these' => 'params'}) { mock_country(:save => false) }
          post :create, :country => {'these' => 'params'}
          assigns(:record).should be(mock_country)
        end
      
        it "render failure json and error message if format json" do
          @grid.model.stub(:new) { mock_country(:save => false) }
          mock_country(:save => false).stub_chain(:errors, :full_messages, :join).with("\n").and_return("country_errors")
          post :create, :country => {}, :format => :json  
          response.body.should == {:success => false, :error_message => "country_errors" }.to_json
        end
      end
    end
    
    describe "post 'update'" do
      describe "with valid params" do
        it "updates the requested record" do
          @grid.model.stub(:find).with("37") { mock_country }
          mock_country.should_receive(:update_attributes).with({'these' => 'params'})
          put :update, :id => 37, :item => {'these' => 'params'}
        end

        it "assigns the requested record as @record" do
          @grid.model.stub(:find) { mock_country(:update_attributes => true) }
          put :update, :id => "1", :item => {'these' => 'params'}
          assigns(:record).should be(mock_country)
        end
        
        it "render success json if format json" do
          @grid.model.stub(:find) { mock_country(:update_attributes => true) }
          put :update, :id => "1", :item => {'these' => 'params'}, :format => :json
          response.body.should == {:success => true}.to_json 
        end
      end

      describe "with invalid params" do
        it "assigns the record as @record" do
          @grid.model.stub(:find) { mock_country(:update_attributes => false) }
          put :update, :id => "1", :item => {'these' => 'params'}
          assigns(:record).should be(mock_country)
        end
        
        it "render failure json and error message if format json" do
          @grid.model.stub(:find) { mock_country(:update_attributes => false) }
          mock_country(:update_attributes => false).stub_chain(:errors, :full_messages, :join).with("\n").and_return("country_errors")
          put :update, :id => "1", :item => {'these' => 'params'}, :format => :json
          response.body.should == {:success => false, :error_message => "country_errors" }.to_json
        end
      end
    end
    
    describe "delete 'destroy'" do
      before :each do
        #@grid.model.stub!(:transaction) { nil }
      end
      
      it "success to destroy the requested county" do
        ids = ['37','38']
        mock_country_1 = mock("Country_1")
        mock_country_2 = mock("Country_2")
        mock_countries = [mock_country_1, mock_country_2] 
        
        @grid.model.stub!(:find).with(ids).and_return(mock_countries)
        @grid.model.should_receive(:transaction).and_yield
        mock_countries.should_receive(:each).and_yield(mock_country_1).and_yield(mock_country_2)
        
        mock_country_1.should_receive(:destroy)
        mock_country_2.should_receive(:destroy)
        
        delete :destroy, :id => "37,38", :format => :json
        response.body.should == {:success => true}.to_json
      end
      
      it "fails to destroy the requested county" do
        ids = ['37','38']
        mock_country_1 = mock("Country_1")
        mock_country_2 = mock("Country_2")
        mock_countries = [mock_country_1, mock_country_2] 
        
        # assume mock_country_1 destroy failed
        mock_country_1.stub!(:destroy).and_raise(Exception.new("can't destroy"))
        
        @grid.model.stub!(:find).with(ids).and_return(mock_countries)
        @grid.model.should_receive(:transaction).and_yield
        mock_countries.should_receive(:each).and_yield(mock_country_1).and_yield(mock_country_2)
        
        mock_country_1.should_receive(:destroy)
        mock_country_2.should_not_receive(:destroy)

        delete :destroy, :id => "37,38", :format => :json
        response.body.should == {:success => false, :error_message => "can't destroy" }.to_json
      end
    end
  end
  
  describe "Self defined methods" do
    it "should include actions from WulinMaster::Actions" do
      WulinMaster::ScreenController.should_receive(:send).with(:include, WulinMaster::Actions)
      WulinMaster::ScreenController.load_actions
    end
  end
end

  
  

  