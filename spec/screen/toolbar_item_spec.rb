require "spec_helper"
require './lib/wulin_master/components/grid/toolbar_item'

describe WulinMaster::ToolbarItem do
  before :each do
    @item = WulinMaster::ToolbarItem.new("Excel",
                                         icon: "excel_icon", javascript: "alert('export excel')", class: "action", id: "excel")
  end

  it "should has title, javascript, icon, options after initialize" do
    pending 'fix'
    @item.title.should == "Excel"
    @item.javascript.should == "alert('export excel')"
    @item.icon.should == "excel_icon"
    @item.options.should == {class: "action", id: "excel", href: "#"}
  end

  it "should respond to javascript?" do
    @item.should respond_to(:javascript?)
    @item.javascript?.should == true

    @item.javascript = nil
    @item.javascript?.should == false
  end

  it "should respond to icon?" do
    @item.should respond_to(:icon?)
    @item.icon?.should == true

    @item.icon = nil
    @item.icon?.should == false
  end

  it "should has anchor_tag_options" do
    pending 'fix'
    @item.should respond_to(:anchor_tag_options)
    # when item has both icon and javascript
    @item.anchor_tag_options.should == {class: "action toolbar_icon_excel_icon", id: "excel", href: "#", onclick: "alert('export excel'); return false;"}

    # when item has only icon
    @item.stub!(:javascript?) { false }
    @item.anchor_tag_options.should == {class: "action toolbar_icon_excel_icon", id: "excel"}

    # when item has only javascript
    @item.stub!(:icon?) { false }
    @item.stub!(:javascript?) { true }
    @item.anchor_tag_options.should == {class: "action", id: "excel", href: "#", onclick: "alert('export excel'); return false;"}

    # when item has no icon nor javascript
    @item.stub!(:icon?) { false }
    @item.stub!(:javascript?) { false }
    @item.anchor_tag_options.should == {class: "action", id: "excel"}
  end

  it "should render the right template" do
    pending 'fix'
    view = @item.render
    view.should include("<div class=\"toolbar_item\">")
    view.should include("<span>Excel</span>")
    view.should include("<a class='action toolbar_icon_excel_icon' id='excel' href='#' onclick='alert('export excel'); return false;'")
  end
end
