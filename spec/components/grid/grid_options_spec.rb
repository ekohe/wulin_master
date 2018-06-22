# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/component'
require './lib/wulin_master/components/grid/grid'
require './lib/wulin_master/components/grid/grid_options'

describe WulinMaster::GridOptions do
  it 'should return 60 as custom row height' do
    class PostGrid < WulinMaster::Grid
      row_height 60
    end
    options = PostGrid.options_pool.reduce({}) { |h, v| h.merge v }

    expect(options[:rowHeight]).to eq(60)
  end
end
