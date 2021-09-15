# frozen_string_literal: true

require "spec_helper"
require "./lib/wulin_master/components/component"
require "./lib/wulin_master/components/grid/grid"

describe WulinMaster::Grid do
  before :each do
    class Post < ApplicationRecord; end

    class PostGrid < WulinMaster::Grid; end
  end

  it "should have a default title" do
    PostGrid.title(false)
    expect(PostGrid.title).to eq("Posts")
  end

  it "should has the default model" do
    PostGrid.model(false)
    expect(PostGrid.model).to eq(Post)
  end

  it "should has the default path" do
    PostGrid.path(false)
    expect(PostGrid.path).to eq("/posts")
  end
end
