require 'rails_helper'
require './lib/wulin_master/actions'
require './app/controllers/wulin_master/screen_controller'

class CountriesController < WulinMaster::ScreenController
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
      # WulinMaster::ScreenController.load_actions
      # @grid = WulinMaster::Grid.new("country")
      # @grid. model(Country)
      # @grid.stub(:model) { Country }
      # controller.stub(:grid) { @grid }
    end

    describe "get 'index'" do
      it "should render index template if request format :html" do
        pending 'fix'
        get :index, :format => :html
        response.should render_template(:index)
      end

      describe "format json" do
        before :each do
          Country.stub(:count) { 100 }
          Country.stub(:all) { [] }
          @mock_model = double("Country")
          controller.query = @mock_model
        end

        it "should invoke methods of building filters, paginations, ordering, selection and fire callbacks" do
          pending 'fix'
          @query_origin = double("query")
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
          pending 'fix'
          controller.stub(:construct_filters) { true }
          controller.stub(:parse_pagination) { true }
          controller.stub(:parse_ordering) { true }
          controller.stub(:add_select) { true }
          controller.stub(:render_json) { "" }
          get :index, :format => :json
          assigns(:query).should == controller.grid.model
          assigns(:count).should == 100
          assigns(:objects).should == []
        end

        it "should render json object as the response" do
          pending 'fix'
          @json_obj = {:offset => 100, :total => 1000, :count => 100, :rows => ["China", "USA"]}.to_json
          controller.stub(:construct_filters) { true }
          controller.stub(:parse_pagination) { true }
          controller.stub(:parse_ordering) { true }
          controller.stub(:add_select) { true }
          controller.stub(:render_json) {@json_obj}
          get :index, :format => :json
          response.body.should == @json_obj
        end

        it "should apply filter on the grid when calling construct_filters if given filter params" do
          pending 'fix'
          controller.stub(:params).and_return({:filters => [{:column => "name", :value => "China"}]})
          @grid.should_receive(:apply_filter).with(@mock_model, "name", "China")
          controller.send(:construct_filters)
        end

        it "should do nothing when calling construct_filters if no filter params given" do
          controller.stub(:params).and_return({})
          @grid.should_not_receive(:apply_filter)
          controller.send(:construct_filters)
        end

        it "should invoke limit and offset on the query according to params count and offset when calling parse_pagination if params given" do
          pending 'fix'
          limited = []
          offseted = []
          controller.stub(:params).and_return({:count => 100, :offset => 200})
          controller.query.stub(:limit) { limited }
          limited.stub(:offset) { offseted }
          controller.query.should_receive(:limit).with(100)
          limited.should_receive(:offset).with(200)
          controller.send(:parse_pagination)
        end

        it "should invoke limit and offset on the query with default value when calling parse_pagination if params not given " do
          pending 'fix'
          limited = []
          offseted = []
          controller.stub(:params).and_return({})
          controller.query.stub(:limit) { limited }
          limited.stub(:offset) { offseted }
          controller.query.should_receive(:limit).with(200)
          limited.should_receive(:offset).with(0)
          controller.send(:parse_pagination)
        end

        it "should invoke order on query when calling parse_ordering if params given" do
          pending 'fix'
          @grid.stub(:sql_columns) { ["name", "code"] }
          controller.stub(:params).and_return({:sort_col => "code", :sort_dir => "DESC"})
          controller.query.should_receive(:order).with("code DESC")
          controller.send(:parse_ordering)
        end

        it "should invoke order on query with default value when calling parse_ordering if params not given" do
          pending 'fix'
          @grid.stub(:sql_columns) { ["name", "code"] }
          controller.stub(:params).and_return({})
          controller.query.should_receive(:order).with("name ASC")
          controller.send(:parse_ordering)
        end

        it "should invoke select on query when calling add_select" do
          pending 'fix'
          @grid.stub(:sql_select) { "sql_select" }
          controller.query.should_receive(:select).with("sql_select")
          controller.send(:add_select)
        end

        it "should return a json object after calling render_json" do
          pending 'fix'
          @grid.stub(:arraify) { ["China", "USA"] }
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
          pending 'fix'
          @grid.model.stub(:new).with({'these' => 'params'}) { mock_country(:save => true) }
          post :create, :country => {'these' => 'params'}
          assigns(:record).should be(mock_country)
        end

        it "render success json if format json" do
          pending 'fix'
          @grid.model.stub(:new) { mock_country(:save => true) }
          post :create, :country => {}, :format => :json
          response.body.should == {:success => true}.to_json
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved record as @record" do
          pending 'fix'
          @grid.model.stub(:new).with({'these' => 'params'}) { mock_country(:save => false) }
          post :create, :country => {'these' => 'params'}
          assigns(:record).should be(mock_country)
        end

        it "render failure json and error message if format json" do
          pending 'fix'
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
          pending 'fix'
          @grid.model.stub(:find).with("37") { mock_country }
          mock_country.should_receive(:update_attributes).with({'these' => 'params'})
          put :update, :id => 37, :item => {'these' => 'params'}
        end

        it "assigns the requested record as @record" do
          pending 'fix'
          @grid.model.stub(:find) { mock_country(:update_attributes => true) }
          put :update, :id => "1", :item => {'these' => 'params'}
          assigns(:record).should be(mock_country)
        end

        it "render success json if format json" do
          pending 'fix'
          @grid.model.stub(:find) { mock_country(:update_attributes => true) }
          put :update, :id => "1", :item => {'these' => 'params'}, :format => :json
          response.body.should == {:success => true}.to_json
        end
      end

      describe "with invalid params" do
        it "assigns the record as @record" do
          pending 'fix'
          @grid.model.stub(:find) { mock_country(:update_attributes => false) }
          put :update, :id => "1", :item => {'these' => 'params'}
          assigns(:record).should be(mock_country)
        end

        it "render failure json and error message if format json" do
          pending 'fix'
          @grid.model.stub(:find) { mock_country(:update_attributes => false) }
          mock_country(:update_attributes => false).stub_chain(:errors, :full_messages, :join).with("\n").and_return("country_errors")
          put :update, :id => "1", :item => {'these' => 'params'}, :format => :json
          response.body.should == {:success => false, :error_message => "country_errors" }.to_json
        end
      end
    end

    describe "delete 'destroy'" do
      before :each do
        #@grid.model.stub(:transaction) { nil }
      end

      it "success to destroy the requested county" do
        pending 'fix'
        ids = ['37','38']
        mock_country_1 = double("Country_1")
        mock_country_2 = double("Country_2")
        mock_countries = [mock_country_1, mock_country_2]

        @grid.model.stub(:find).with(ids).and_return(mock_countries)
        @grid.model.should_receive(:transaction).and_yield
        mock_countries.should_receive(:each).and_yield(mock_country_1).and_yield(mock_country_2)

        mock_country_1.should_receive(:destroy)
        mock_country_2.should_receive(:destroy)

        delete :destroy, :id => "37,38", :format => :json
        response.body.should == {:success => true}.to_json
      end

      it "fails to destroy the requested county" do
        pending 'fix'
        ids = ['37','38']
        mock_country_1 = double("Country_1")
        mock_country_2 = double("Country_2")
        mock_countries = [mock_country_1, mock_country_2]

        # assume mock_country_1 destroy failed
        mock_country_1.stub(:destroy).and_raise(Exception.new("can't destroy"))

        @grid.model.stub(:find).with(ids).and_return(mock_countries)
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
      pending 'fix'
      controller.class.should_receive(:send).with(:include, WulinMaster::Actions)
      # controller.class.load_actions
    end

    it "should indicate the screen by invoking controller_for_screen" do
      pending 'fix'
      controller.class.should respond_to(:controller_for_screen)

      @event_screen = double("Screen")
      # controller.class.should_receive(:load_actions)

      controller.class.controller_for_screen(@event_screen)
      controller.class.screen.should == @event_screen
    end

    it "should indicate the main grid it belongs to by involking controller_for_grid" do
      pending 'fix'
      controller.class.should respond_to(:controller_for_grid)

      @event_grid = WulinMaster::Grid.new("event")
      WulinMaster::Grid.stub(:get).with("event") { @event_grid }

      WulinMaster::Grid.should_receive(:get).with("event")
      # controller.class.should_receive(:load_actions)

      controller.class.controller_for_grid("event")
      controller.class.grid.should == @event_grid
      @event_grid.controller_class.should == controller.class
    end


    describe "add callbacks" do
      it 'can add callbacks to the controller' do
        pending 'fix'
        controller.should respond_to(:add_callback)
      end

      it 'should add the method name to callbacks if invoke add_callback without block' do
        pending 'fix'
        mock_method = double("Method")
        controller.callbacks.should == nil
        controller.add_callback(:before_query, mock_method)
        controller.callbacks.should == {before_query: [mock_method]}
      end

      it 'should save the block to callbacks if invoke add_callback with a block' do
        pending 'fix'
        mock_block = double("Block")
        controller.callbacks.should == nil
        controller.add_callback(:before_query) do
          mock_block
        end
        controller.callbacks.should have_key(:before_query)
        controller.callbacks[:before_query].length.should == 1
        controller.callbacks[:before_query].first.should be_a_kind_of(Proc)
      end
    end

    describe "fire callbacks" do
      before :each do
        @mock_callbacks = double("callbacks")
        @mock_cbs = double("some_callbacks")
      end

      it 'can fire callbacks of the controler' do
        pending 'fix'
        controller.should respond_to(:fire_callbacks)
      end

      it 'should do nothing i"f no callbacks existing' do
        pending 'fix'
        controller.stub(:callbacks) {nil}
        controller.should_not_receive(:callbacks).with("before_query")

        controller.fire_callbacks("before_query")
      end

      it 'should do nothing if not found specified callbacks or specified callbacks has no callback in it' do
        pending 'fix'
        controller.stub(:callbacks) {@mock_callbacks}
        controller.stub(:callbacks).with("before") {@mock_cbs}
        @mock_cbs.stub(:blank?) {true}

        @mock_cbs.should_not_receive(:each)
        controller.fire_callbacks("before")
      end


      it 'should invoke every callback in the specified callbacks if found' do
        pending 'fix'
        @cb_1 = double("callback")
        @cb_2 = double("callback")
        @cb_3 = double("callback")

        @cb_1.stub(:class) {Proc}
        controller.stub(:respond_to?).with(@cb_2) {true}
        controller.stub(:respond_to?).with(@cb_3) {false}

        @mock_cbs = [@cb_1, @cb_2, @cb_3]

        controller.stub(:callbacks) {@mock_callbacks}
        controller.stub(:callbacks).with("before") {@mock_cbs}

        @mock_cbs.should_receive(:each).and_yield(@cb_1).and_yield(@cb_2).and_yield(@cb_3)
        @cb_1.should_receive(:call)   # should call proc
        controller.should_receive(:send).with(@cb_2)    # should invoke existing method
        controller.should_not_receive(:send).with(@cb_3)    # should not invoke not-existing method

        controller.fire_callbacks("before")
      end
    end
  end
end
