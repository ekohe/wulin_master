# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/screen/screen'

describe WulinMaster::Screen do
  before :each do
    class PostScreen < WulinMaster::Screen; end
  end

  it 'should push an inherited screen into class variable screens' do
    expect(WulinMaster::Screen.screens).to eq([PostScreen])
  end

  it 'should have a default title' do
    PostScreen.title(false)
    expect(PostScreen.title).to eq('Post')
  end

  it 'should has the default path' do
    expect(PostScreen.path).to eq('/posts')
  end
end
