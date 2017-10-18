# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/screen/screen'

describe WulinMaster::Screen do
  before :each do
    class BookScreen < WulinMaster::Screen; end
  end

  it 'should push an inherited screen into class variable screens' do
    expect(WulinMaster::Screen.screens).to eq([BookScreen])
  end

  it 'should have a default title' do
    BookScreen.title(false)
    expect(BookScreen.title).to eq('Book')
  end

  it 'should has the default path' do
    expect(BookScreen.path).to eq('/books')
  end
end
