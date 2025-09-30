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

    context 'when the operator is "exact"' do
      it "generates exact match SQL conditions without wildcards" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) = ?", "value"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "value", nil, "exact")
      end

      it "generates exact match SQL conditions for multiple values with commas" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) = ? OR CAST(column_name AS TEXT) = ?", "value1", "value2"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "value1,value2", nil, "exact")
      end

      it "generates exact match SQL conditions for multiple values with ampersands" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) = ? AND CAST(column_name AS TEXT) = ?", "value1", "value2"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "value1&value2", nil, "exact")
      end

      it "generates exact match SQL conditions for negation with exclamation" do
        expect(query).to receive(:where).with(["(CAST(column_name AS TEXT) <> ? OR column_name IS NULL)", "value"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "!value", nil, "exact")
      end

      it "allows exact match with values containing special characters" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) = ?", "TP5102.1"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "TP5102.1", nil, "exact")
      end

      it "allows exact match with values containing comma in the search term" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) = ? OR CAST(column_name AS TEXT) = ?", "TP5102.1", "L1401.1"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "TP5102.1,L1401.1", nil, "exact")
      end

      it "uses LIKE when value starts or ends with %" do
        expect(query).to receive(:where).with(["CAST(column_name AS TEXT) LIKE ?", "value%"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "value%", nil, "exact")
      end

      it "uses NOT LIKE for negation when value starts or ends with %" do
        expect(query).to receive(:where).with(["(CAST(column_name AS TEXT) NOT LIKE ? OR column_name IS NULL)", "value%"])
        WulinMaster::SqlQuery.string_query(query, "column_name", "!value%", nil, "exact")
      end
    end
  end
end
