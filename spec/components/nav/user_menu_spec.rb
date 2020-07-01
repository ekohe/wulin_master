# frozen_string_literal: true

require 'spec_helper'
require './lib/wulin_master/components/nav/app_bar_menu'

describe WulinMaster::AppBarMenu do
  subject { described_class }

  it 'has a default menus {}' do
    expect(subject.menus).to eq({})
  end

  context 'add_menu' do
    before do
      described_class.add_menu :logout, icon: :lock, url: "/logout"
    end

    it 'added logout menus' do
      expect(subject.menus).to have_key(:logout)
      expect(subject.menus[:logout]).to include(:title, :icon, :url)
    end
  end

  context 'remove_menu' do
    before do
      described_class.add_menu :logout, icon: :lock, url: "/logout"
      described_class.remove_menu :logout
    end

    it 'removed logout menu' do
      expect(subject.menus).not_to have_key(:logout)
    end
  end
end
