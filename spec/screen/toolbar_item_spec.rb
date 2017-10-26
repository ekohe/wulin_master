# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/grid/toolbar_item'

describe WulinMaster::ToolbarItem do
  before :each do
    @item = WulinMaster::ToolbarItem.new('Excel',
                                         icon: 'excel_icon',
                                         javascript: 'alert("export excel")',
                                         class: 'action',
                                         id: 'excel')
  end

  it 'should has title, javascript, icon, options after initialize' do
    expect(@item.title).to eq('Excel')
    expect(@item.javascript).to eq('alert("export excel")')
    expect(@item.icon).to eq('excel_icon')
    expect(@item.options).to eq(class: 'action', id: 'excel', href: 'javascript:void(0);')
  end

  it 'should respond to javascript?' do
    expect(@item.javascript?).to eq(true)
    @item.javascript = nil
    expect(@item.javascript?).to eq(false)
  end

  it 'should respond to icon?' do
    expect(@item.icon?).to eq(true)
    @item.icon = nil
    expect(@item.icon?).to eq(false)
  end

  it 'should have anchor_tag_options' do
    # when item has both icon and javascript
    expect(@item.anchor_tag_options).to eq(class: "waves-effect waves-circle tooltipped action",
                                           id: "excel",
                                           href: "#",
                                           onclick: "alert(\"export excel\"); return false;",
                                           "data-position": "bottom",
                                           "data-delay": "50",
                                           "data-tooltip": "Excel")

    # when item has only icon
    allow(@item).to receive(:javascript?).and_return(false)
    expect(@item.anchor_tag_options).to eq(class: "waves-effect waves-circle tooltipped action",
                                           id: 'excel',
                                           "data-position": "bottom",
                                           "data-delay": "50",
                                           "data-tooltip": "Excel")

    # when item has only javascript
    allow(@item).to receive(:icon?).and_return(false)
    allow(@item).to receive(:javascript?).and_return(true)
    expect(@item.anchor_tag_options).to eq(class: "waves-effect waves-circle tooltipped action",
                                           id: 'excel',
                                           href: '#',
                                           onclick: 'alert("export excel"); return false;',
                                           "data-position": "bottom",
                                           "data-delay": "50",
                                           "data-tooltip": "Excel")

    # when item has no icon nor javascript
    allow(@item).to receive(:icon?).and_return(false)
    allow(@item).to receive(:javascript?).and_return(false)
    expect(@item.anchor_tag_options).to eq(class: "waves-effect waves-circle tooltipped action",
                                           id: 'excel',
                                           "data-position": "bottom",
                                           "data-delay": "50",
                                           "data-tooltip": "Excel")
  end
end
