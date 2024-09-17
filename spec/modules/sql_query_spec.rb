require "rails_helper"

RSpec.describe WulinMaster::SqlQuery do
  describe "#string_query" do
    let(:query) { double("ActiveRecord::Relation") }

    context "when the filter contains a single value" do
      it "generates the correct SQL conditions" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) ILIKE ?", "value%"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "value", nil)
      end
    end

    context "when the filter contains multiple values separated by commas" do
      it "generates the correct SQL conditions with OR" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) ILIKE ? OR CAST(column_name AS TEXT) ILIKE ?", "value1%", "value2%"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "value1,value2", nil)
      end
    end

    context "when the filter contains multiple values separated by ampersands" do
      it "generates the correct SQL conditions with AND" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) ILIKE ? AND CAST(column_name AS TEXT) ILIKE ?", "value1%", "value2%"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "value1&value2", nil)
      end
    end

    context 'when the operator is "NOT ILIKE"' do
      it "generates the correct SQL conditions for a NOT ILIKE operation" do
        expect(query).to receive(:where).with(["(CAST(column_name AS TEXT) NOT ILIKE ? OR column_name IS NULL)", "value%"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "value", nil, "NOT ILIKE")
      end
    end
  end
end
