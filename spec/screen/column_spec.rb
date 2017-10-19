# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/grid/column'

describe WulinMaster::Column do
  before :each do
    @grid = double('grid')
    @column = WulinMaster::Column.new('title', @grid)
  end

  it 'should has a name' do
    expect(@column.name).to eq('title')
  end

  it 'should has default options' do
    expect(@column.options).to eq(width: 150, sortable: true)
  end

  it 'can has customized options' do
    @column = WulinMaster::Column.new('title', @grid, width: 100, editable: false, label: 'Title')
    expect(@column.options).to eq(width: 100, sortable: true, editable: false, label: 'Title')
  end

  it 'should has a default label' do
    expect(@column.label).to eq('Title')
  end

  it 'can has customized label' do
    @column = WulinMaster::Column.new('title', @grid, label: 'Book Title')
    expect(@column.label).to eq('Book Title')
  end
end
