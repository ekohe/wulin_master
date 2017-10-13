# frozen_string_literal: true

require 'spec_helper'
require './app/controllers/wulin_master/menuable'
require './app/controllers/wulin_master/home_controller'
require './lib/wulin_master/menu/menu'

class ApplicationController < ActionController::Base
  def self.define_menu
    menu do |c|
      submenu 'Settings' do
        item MasterUserDetailInvitationScreen, active_paths: c.clients_path(screen: 'MasterInvitationDetailUserScreen')
      end
    end
  end
end

class HomepageController < WulinMaster::HomeController
end

describe HomepageController, type: :controller do
  def mock_item
    @mock_item ||= mock("Item")
  end

  def mock_entry
    @mock_entry ||= mock("Entry")
  end

  def mock_block
    @mock_block ||= mock("Block")
  end

  before :each do
    @menu = WulinMaster::Menu.new
    @submenu = WulinMaster::SubMenu.new("sub")
    allow_message_expectations_on_nil
    @controller = WulinMaster::HomeController.new
  end

  # describe "get 'index'" do
  #   it "should render home partial" do
  #     pending 'fix'
  #     get :index, format: :html
  #     response.should render_template(:home) # because there is no index template now
  #   end
  # end

  # it "should invoke menu with a block to render menu on page" do
  #   pending 'fix'
  #   @controller.class.should respond_to(:menu)
  #
  #   WulinMaster::Menu.stub(:new).and_return(@menu)
  #   WulinMaster::Menu.should_receive(:new)
  #   @controller.class.menu do
  #     mock_block
  #   end
  # end

  # it "should invoke menu without a block to only return class variable: menu" do
  #   pending 'fix'
  #   WulinMaster::Menu.should_not_receive(:new)
  #   @controller.class.menu.should be_a_kind_of(WulinMaster::Menu)
  # end

  # it "should invoke submenu to render submenus on page" do
  #   pending 'fix'
  #   @controller.class.should respond_to(:submenu)
  #
  #   WulinMaster::SubMenu.stub!(:new).and_return(@submenu)
  #   WulinMaster::SubMenu.should_receive(:new).with("Locations")
  #   @controller.class.menu.should_receive(:<<).with(@submenu)
  #   @controller.class.submenu("Locations") do
  #     mock_block
  #   end
  # end

  describe "Invoke method: item to render menu items on page" do
    it "should respond to method: item" do
      expect(@controller.class).to respond_to(:item)
    end

    # it "should add nothing to menu or submenu if menu is nil" do
    #   pending 'fix'
    #   @controller.class.menu = nil
    #
    #   @controller.class.menu.should_not_receive(:<<)
    #   @controller.class.submenu.should_not_receive(:<<)
    #   @controller.class.item(mock_item)
    # end

    # it "should add item to submenu if submenu is not nil" do
    #   pending 'fix'
    #   @controller.class.menu = []
    #   @controller.class.submenu = []
    #   mock_item.stub(:title) { "title" }
    #   mock_item.stub(:path) { "path" }
    #
    #   WulinMaster::MenuEntry.should_receive(:new).with("title", "path").and_return(mock_entry)
    #   @controller.class.menu.should_not_receive(:<<)
    #   @controller.class.submenu.should_receive(:<<).with(mock_entry)
    #   @controller.class.item(mock_item)
    # end

    # it "should add item to menu if submenu is nil" do
    #   pending 'fix'
    #   @controller.class.submenu = nil
    #   mock_item.stub(:title) { "title" }
    #   mock_item.stub(:path) { "path" }
    #
    #   WulinMaster::MenuEntry.should_receive(:new).with("title", "path").and_return(mock_entry)
    #   @controller.class.menu.should_receive(:<<).with(mock_entry)
    #   @controller.class.submenu.should_not_receive(:<<)
    #   @controller.class.item(mock_item)
    # end
  end
end
