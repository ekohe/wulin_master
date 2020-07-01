# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/nav/app_bar_menu'

describe WulinMaster::AppBarMenu do
  subject { described_class }

  # ActivityMenu has been added in the file lib/wulin_master.rb
  it 'has a default menus [ActivityMenu]' do
    expect(subject.menus).to eq([ActivityMenu])
  end

  context 'add_menu' do
    before do
      ActivityMenu.add_menu(label: 'activity menu')
    end

    it 'alerts ActivityMenu added {label: "activity menu"}' do
      expect(ActivityMenu.menus).to contain_exactly({label: 'activity menu'})
    end
  end
end
