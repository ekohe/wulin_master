# frozen_string_literal: true

require "spec_helper"

describe WulinMaster::HostUser do
  # The grid partials ask `current_user?`, and they render in the HOST's view context -- so the
  # module has to arrive through the engine's helper, not through the controllers that include it.
  # No spec renders a view, so this is what would catch the include going missing.
  it "reaches the views through the engine's helper" do
    expect(ApplicationController.helpers).to respond_to(:current_user?)
  end
end
