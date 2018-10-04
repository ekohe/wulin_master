# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/grid/column'

describe WulinMaster::Column do
  before :each do
    @grid = double(:grid)
    @model = double(:model)
    allow(@grid).to receive(:model) { @model }
    @column = WulinMaster::Column.new(:title, @grid)
  end

  it 'should have a name' do
    expect(@column.name).to eq(:title)
  end

  it 'should have default options' do
    expect(@column.options).to eq(width: 150, sortable: true)
  end

  it 'can have customized options' do
    @column = WulinMaster::Column.new(:title, @grid, width: 100, editable: false, label: 'Title')
    expect(@column.options).to eq(width: 100, sortable: true, editable: false, label: 'Title')
  end

  it 'should have a default label from the localization file' do
    expect(@model).to receive(:human_attribute_name) { 'Human title' }
    expect(@column.label).to eq('Human title')
  end

  it 'can have customized label' do
    @column = WulinMaster::Column.new(:title, @grid, label: 'Post Title')
    expect(@column.label).to eq('Post Title')
  end
end
