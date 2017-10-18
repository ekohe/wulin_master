# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/component'
require './lib/wulin_master/components/grid/grid'

describe WulinMaster::Grid do
  before :each do
    class Book < ApplicationRecord; end
    class BookGrid < WulinMaster::Grid; end
  end

  it 'should have a default title' do
    BookGrid.title(false)
    expect(BookGrid.title).to eq('Book')
  end

  it 'should has the default model' do
    BookGrid.model(false)
    expect(BookGrid.model).to eq(Book)
  end

  # it 'should has the default path' do
  #   BookGrid.path(false)
  #   expect(BookGrid.path).to eq('/books')
  # end
end
