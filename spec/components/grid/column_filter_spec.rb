# frozen_string_literal: true

require "spec_helper"

describe WulinMaster::ColumnFilter do
  subject(:query) { WulinMaster::GridState }

  describe "#filter_by_datetime" do
    it "contains time zone offset" do
      fc = FakeClass.new(:created_at, GridStateGrid)
      allow(Time.zone).to receive(:name).and_return("Etc/UTC")

      final_query = fc.send(:filter_by_datetime, query, "=", "created_at", "00:00")

      expect(final_query.to_sql).to match(/time zone 'Etc\/UTC'/i)
    end
  end
end

class FakeClass < WulinMaster::Column
  include WulinMaster::ColumnFilter
end
