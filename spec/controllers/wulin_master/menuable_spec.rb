# frozen_string_literal: true

require "spec_helper"
require "./app/controllers/wulin_master/home_controller"

describe WulinMaster::Menuable do
  it "builds each request's menu for its own user when two requests build it at the same time" do
    controller_class = Class.new(WulinMaster::HomeController) { attr_accessor :current_user }
    paused = Queue.new
    resume = Queue.new
    controller_class.menu do |c|
      if c.current_user == "first"
        paused << true
        resume.pop
      end
      c.class.item "Menu for #{c.current_user}", authorized?: ->(user) { user == c.current_user }
    end
    first = controller_class.new.tap { |c| c.current_user = "first" }
    second = controller_class.new.tap { |c| c.current_user = "second" }

    first_menu = Thread.new { first.menu }
    paused.pop
    second_menu = second.menu
    resume << true

    expect(first_menu.value.map(&:title)).to eq(["Menu for first"])
    expect(second_menu.map(&:title)).to eq(["Menu for second"])
  end
end
