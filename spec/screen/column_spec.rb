# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/grid/column'

describe WulinMaster::Column do
  before :each do
    @grid = double('grid')
    @column = WulinMaster::Column.new('book_name', @grid)
  end

  it 'should has a name' do
    expect(@column.name).to eq('book_name')
  end

  it 'should has default options' do
    expect(@column.options).to eq(width: 150, sortable: true)
  end

  it 'can has customized options' do
    @column = WulinMaster::Column.new('book_name', @grid, width: 100, editable: false, label: 'Book Name')
    expect(@column.options).to eq(width: 100, sortable: true, editable: false, label: 'Book Name')
  end

  it 'should has a default label' do
    expect(@column).to respond_to(:label)
    expect(@column.label).to eq('Book name')
  end

  it 'can has customized label' do
    @column = WulinMaster::Column.new('book_name', @grid, label: 'Book Name')
    expect(@column.label).to eq('Book Name')
  end

  # it 'should respond to to_column_model' do
  #   pending 'fix'
  #   expect(@column).to respond_to(:to_column_model)
  #   expect(@column).to respond_to(:sql_type)
  #   allow(@column).to receive(:sql_type).and_return(String)
  #   expected_result = {id: 'book_name', name: 'Book name', field: 'book_name', type: String, width: 80, sortable: true, editable: true}
  #   expect(@column.to_column_model('BookScreen')).to eq(expected_result)
  # end

  # it 'can apply filter' do
  #   pending 'fix'
  #   expect(@column).to respond_to(:apply_filter)
  #   query = double('Book')
  #   @column.apply_filter(query, '').should == query
  #
  #   # filter string type
  #   @column.stub(:sql_type) { String }
  #   sql_result = nil
  #   query.stub(:where).with('UPPER(book_name) LIKE UPPER("China%")') { sql_result }
  #   @column.apply_filter(query, 'China').should == sql_result
  #
  #   # filter datetime type
  #   @column.stub(:sql_type) { :datetime }
  #   query.stub(:where).with('to_char(book_name, "YYYY-MM-DD") LIKE UPPER("2011-05-03%")') { sql_result }
  #   @column.apply_filter(query, '2011-05-03').should == sql_result
  # end
end
