# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/nav/app_bar_menu'

describe WulinMaster::AppBarMenu do
  subject { described_class }

  # ActivityMenu has been added in the file lib/wulin_master.rb
  it 'has a default menus named app_bar_menu' do
    expect(subject.menus.name).to eq(:app_bar_menu)
  end

  context 'add_menu' do
    before do
      described_class.menus.add_menu(:user_menu)
    end

    it 'has a menus which has a main menu named user_menu' do
      expect(described_class.menus.menus.last.name).to eq(:user_menu)
    end
  end
end
