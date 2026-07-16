# frozen_string_literal: true

require "spec_helper"

describe WulinMaster::ColumnFilter do
  subject(:query) { WulinMaster::GridState }

  describe "#filter_by_datetime" do
    it "uses the Rails app time zone by default" do
      fc = FakeClass.new(:created_at, GridStateGrid)
      allow(Time.zone).to receive(:tzinfo).and_return(ActiveSupport::TimeZone["America/New_York"].tzinfo)

      final_query = fc.send(:filter_by_datetime, query, "=", "grid_states.created_at", "00:00")

      expect(final_query.to_sql).to match(/time zone 'America\/New_York'/i)
    end

    it "uses the column time_zone option when present" do
      fc = FakeClass.new(:created_at, GridStateGrid, time_zone: "UTC")

      final_query = fc.send(:filter_by_datetime, query, "=", "grid_states.created_at", "13/07/2026 11:")

      expect(final_query.to_sql).to match(/time zone 'UTC'/i)
      expect(final_query.to_sql).not_to match(/time zone 'America\/New_York'/i)
    end

    it "includes seconds in the filter format when datetime_format is :with_seconds" do
      fc = FakeClass.new(:created_at, GridStateGrid, time_zone: "UTC", datetime_format: :with_seconds)

      final_query = fc.send(:filter_by_datetime, query, "=", "grid_states.created_at", "13/07/2026 11:59:45")

      expect(final_query.to_sql).to include("DD/MM/YYYY HH24:MI:SS")
      expect(final_query.to_sql).to match(/time zone 'UTC'/i)
    end

    it "keeps the minute filter format by default" do
      fc = FakeClass.new(:created_at, GridStateGrid)

      final_query = fc.send(:filter_by_datetime, query, "=", "grid_states.created_at", "13/07/2026 11:")

      expect(final_query.to_sql).to include("DD/MM/YYYY HH24:MI")
      expect(final_query.to_sql).not_to include("DD/MM/YYYY HH24:MI:SS")
    end

    it "filters virtual datetime columns using their source" do
      fc = FakeClass.new(
        :created_at_local,
        GridStateGrid,
        source: :created_at,
        sql_expression: "grid_states.created_at",
        sql_type: :datetime
      )
      adapter = WulinMaster::SqlAdapter.new(WulinMaster::GridState, query)

      final_query = fc.send(:filter_without_reflection, query, "13/07/2026 11:", "equals", :datetime, adapter)

      expect(final_query.to_sql).to include("grid_states.created_at::timestamptz")
      expect(final_query.to_sql).not_to include("grid_states.created_at_local")
      expect(final_query.to_sql).to match(/time zone '#{Regexp.escape(Time.zone.tzinfo.name)}'/i)
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

  describe "#apply_filter with belongs_to include/exclude" do
    let(:column) { FakeClass.new(:room, GridStateGrid) }
    let(:belongs_to_reflection) do
      instance_double(
        ActiveRecord::Reflection::BelongsToReflection,
        macro: :belongs_to,
        foreign_key: "room_id",
        klass: WulinMaster::GridState
      )
    end

    before do
      allow(column).to receive(:reflection).and_return(belongs_to_reflection)
    end

    context "with exclude operator" do
      it "filters on the foreign key with OR IS NULL" do
        final_query = column.apply_filter(query, "1", "exclude")

        expect(final_query.to_sql).to include("grid_states.room_id != '1'")
        expect(final_query.to_sql).to include("grid_states.room_id IS NULL")
      end
    end

    context "with include operator" do
      it "filters on the foreign key with equality" do
        final_query = column.apply_filter(query, "1", "include")

        expect(final_query.to_sql).to include("grid_states.room_id = '1'")
      end
    end
  end
end

class FakeClass < WulinMaster::Column
  include WulinMaster::ColumnFilter
end
