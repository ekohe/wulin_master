# frozen_string_literal: true

require "spec_helper"
require "./app/controllers/wulin_master/home_controller"

class HomepageController < WulinMaster::HomeController; end

describe HomepageController, type: :controller do
  def mock_item
    @mock_item ||= double(:item)
  end

  def mock_entry
    @mock_entry ||= double(:entry)
  end

  def mock_block
    @mock_block ||= double(:block)
  end

  before :each do
    @menu = WulinMaster::Menu.new
    @submenu = WulinMaster::SubMenu.new("Posts")
    allow_message_expectations_on_nil
  end

  describe "get :index" do
    it "should render home partial" do
      routes.draw { get :index, to: "homepage#index" }
      get :index, format: :html
      expect(response).to render_template(:home)
    end
  end

  it "should invoke menu with a block to render menu on page" do
    allow(WulinMaster::Menu).to receive(:new).and_return(@menu)
    expect(WulinMaster::Menu).to receive(:new)
    controller.class.menu do
      mock_block
    end
    controller.menu
  end

  it "should invoke submenu to render submenus on page" do
    allow(WulinMaster::SubMenu).to receive(:new).and_return(@submenu)
    expect(WulinMaster::SubMenu).to receive(:new).with("Posts")
    controller.class.submenu("Posts") do
      mock_block
    end
  end

  describe "Invoke method: item to render menu items on page" do
    it "should respond to method: item" do
      expect(controller.class).to respond_to(:item)
    end

    it "should add item to submenu if submenu is not nil" do
      controller.class.menu { mock_block }
      controller.class.submenu("Posts") { mock_block }
      allow(mock_item).to receive(:title).and_return("Post")
      expect(WulinMaster::MenuEntry).to receive(:new).with("Post", "/", screen_name: nil)
      controller.class.item(mock_item)
    end

    it "should add item to menu if submenu is nil" do
      allow(mock_item).to receive(:title).and_return("Post")
      expect(WulinMaster::MenuEntry).to receive(:new).with("Post", "/", screen_name: nil).and_return(mock_entry)
      expect(controller.menu).to receive(:<<).with(mock_entry)
      expect(controller.class.submenu).not_to receive(:<<).with(mock_entry)
      controller.class.item(mock_item)
    end
  end
end
