require "rails_helper"

describe WulinMaster::Toolbar do
  it "should render a toolbar with the toolbar items" do
    pending 'fix'
    item_1 = WulinMaster::ToolbarItem.new("Excel", :icon => "excel")
    item_2 = WulinMaster::ToolbarItem.new("Filter", :icon => "filter", :javascript => "alert('filter')")
    view_1 = item_1.render
    view_2 = item_2.render

    toolbar = WulinMaster::Toolbar.new([item_1, item_2])
    view = toolbar.render

    view.should include("<div id=\"toolbar\">")
    view.should include(view_1)
    view.should include(view_2)
  end
end
