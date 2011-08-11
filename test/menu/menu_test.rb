require 'test_helper'

class MenuTest < Test::Unit::TestCase
  test 'wulin master menu is an array' do
    menu = WulinMaster::Menu.new
    assert_kind_of Array, menu
  end
end