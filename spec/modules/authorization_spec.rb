require "rails_helper"

RSpec.describe WulinMaster::Authorization do
  let(:controller_class) do
    Class.new do
      include WulinMaster::Authorization

      def controller_name = "posts"

      def action_name = "update"
    end
  end

  describe "#required_permission" do
    context "without wulin_permits' Permission model" do
      before { hide_const("Permission") }

      it "names the controller and action" do
        expect(controller_class.new.required_permission.name).to eq("posts#update")
      end

      it "does not depend on OpenStruct, which Ruby 4.0 no longer loads by default" do
        hide_const("OpenStruct")
        expect(controller_class.new.required_permission).to be_a(WulinMaster::Authorization::RequiredPermission)
      end
    end
  end
end
