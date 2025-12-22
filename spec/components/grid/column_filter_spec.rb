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

  describe "#filter_without_reflection for numeric columns" do
    let(:fc) { FakeClass.new(:id, GridStateGrid) }
    let(:adapter) { WulinMaster::SqlAdapter.new(WulinMaster::GridState, query) }

    before do
      allow(fc).to receive(:sql_type).and_return(:integer)
      allow(fc).to receive(:table_column?).and_return(true)
      allow(fc).to receive(:complete_column_name).and_return("grid_states.id")
    end

    context "when filtering integer column with comma-separated values" do
      it "uses IN clause for comma-separated integers" do
        final_query = fc.send(:filter_without_reflection, query, "1,2", "equals", :integer, adapter)

        expect(final_query.to_sql).to include('"grid_states"."id" IN (1, 2)')
        expect(final_query.to_sql).not_to include("ILIKE")
      end

      it "uses IN clause for three comma-separated values" do
        final_query = fc.send(:filter_without_reflection, query, "1,2,3", "equals", :integer, adapter)

        expect(final_query.to_sql).to include('"grid_states"."id" IN (1, 2, 3)')
        expect(final_query.to_sql).not_to include("ILIKE")
      end
    end

    context "when filtering integer column with single value" do
      it "uses direct equality for a single numeric value" do
        final_query = fc.send(:filter_without_reflection, query, "1", "equals", :integer, adapter)

        # Single values go through the original direct equality path
        expect(final_query.to_sql).to include("grid_states.id =")
        expect(final_query.to_sql).not_to include("ILIKE")
      end
    end

    context "when filtering integer column with not_equals operator" do
      it "uses NOT IN clause for comma-separated values" do
        final_query = fc.send(:filter_without_reflection, query, "1,2", "not_equals", :integer, adapter)

        expect(final_query.to_sql).to include('"grid_states"."id" NOT IN (1, 2)')
        expect(final_query.to_sql).not_to include("ILIKE")
      end
    end

    context "when filtering with complex patterns" do
      it "falls back to string_query for negation patterns" do
        final_query = fc.send(:filter_without_reflection, query, "!1,2", "equals", :integer, adapter)

        # Negation should use string_query, not IN
        expect(final_query.to_sql).not_to include("IN (")
      end

      it "falls back to string_query for AND patterns" do
        final_query = fc.send(:filter_without_reflection, query, "1&2", "equals", :integer, adapter)

        # Should use exact matching via string_query, not IN
        expect(final_query.to_sql).not_to include("IN")
        expect(final_query.to_sql).to include("AND")
      end

      it "falls back to string_query for invalid number format" do
        final_query = fc.send(:filter_without_reflection, query, "12 34-56", "equals", :integer, adapter)

        # Invalid format should not use IN clause
        expect(final_query.to_sql).not_to include("IN (")
      end
    end

    context "when filtering with negative numbers" do
      it "uses IN clause for negative numbers" do
        final_query = fc.send(:filter_without_reflection, query, "-1,2", "equals", :integer, adapter)

        expect(final_query.to_sql).to include('"grid_states"."id" IN (-1, 2)')
      end
    end
  end
end

class FakeClass < WulinMaster::Column
  include WulinMaster::ColumnFilter
end
