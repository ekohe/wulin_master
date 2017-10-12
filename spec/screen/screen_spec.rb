# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/screen/screen'

describe WulinMaster::Screen do
  before :each do
    class DemoScreen < WulinMaster::Screen; end
  end

  it 'should push an inherited screen into class variable screens' do
    expect(WulinMaster::Screen.screens).to eq([DemoScreen])
  end

  it 'should have a default title' do
    DemoScreen.title(false)
    expect(DemoScreen.title).to eq('Demo')
  end

  it 'should assign the title' do
    DemoScreen.title('Demo Screen')
    expect(DemoScreen.title).to eq('Demo Screen')
  end

  it 'should assign the path' do
    DemoScreen.path('/demo_screens')
    expect(DemoScreen.path).to eq('/demo_screens')
  end

  it 'should has the default path' do
    DemoScreen.path(nil)
    expect(DemoScreen.path).to eq('/demos')
  end
end
