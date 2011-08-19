require 'spec_helper'
require 'wulin_master/controllers/actions'
require 'wulin_master/controllers/screen_controller'

class CountriesController < WulinMaster::ScreenController
  include ActionDispatch::Routing::UrlFor
end

describe CountriesController, :type => :controller do
    
  describe "Includes WulinMaster::Actions" do
    before :each do
      WulinMaster::ScreenController.load_actions
    end
    
    describe "get 'index'" do
      it "should render index template if request format :html" do
        get :index
        response.should render_template(:index)
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

  
  

  