# frozen_string_literal: true

require "rails_helper"
require_relative "../../db/migrate/20260721082348_add_columns_to_grid_states"

describe AddColumnsToGridStates do
  let(:migration) { described_class.new }

  def create_state(state_value)
    WulinMaster::GridState.create!(
      user_id: 1,
      grid_name: "test_grid",
      name: "default",
      state_value: state_value.to_json
    )
  end

  after { WulinMaster::GridState.delete_all }

  describe "#up" do
    it "builds columns array from order, width, and visibility" do
      state = create_state(
        "order" => {"0" => "name", "1" => "email", "2" => "id"},
        "width" => {"name" => 200, "email" => 300},
        "visibility" => ["id"]
      )

      migration.up

      columns = JSON.parse(state.reload.state_value)["columns"]
      expect(columns).to eq([
        {"id" => "name", "visible" => true, "width" => 200},
        {"id" => "email", "visible" => true, "width" => 300},
        {"id" => "id", "visible" => false}
      ])
    end

    it "includes filter on the matching column" do
      state = create_state(
        "order" => {"0" => "name", "1" => "rank"},
        "filter" => {"rank" => "10"}
      )

      migration.up

      columns = JSON.parse(state.reload.state_value)["columns"]
      expect(columns.find { |c| c["id"] == "rank" }["filter"]).to eq("10")
      expect(columns.find { |c| c["id"] == "name" }).not_to have_key("filter")
    end

    it "includes sort as lowercase asc/desc on the matching column" do
      state = create_state(
        "order" => {"0" => "name", "1" => "created_at"},
        "sort" => {"sortCol" => "created_at", "sortDir" => "1"}
      )

      migration.up

      columns = JSON.parse(state.reload.state_value)["columns"]
      expect(columns.find { |c| c["id"] == "created_at" }["sort"]).to eq("asc")
      expect(columns.find { |c| c["id"] == "name" }).not_to have_key("sort")
    end

    it "preserves old keys alongside columns" do
      state = create_state(
        "order" => {"0" => "name"},
        "width" => {"name" => 200},
        "visibility" => [],
        "filter" => {"name" => "test"},
        "sort" => {"sortCol" => "name", "sortDir" => "1"}
      )

      migration.up

      val = JSON.parse(state.reload.state_value)
      expect(val).to have_key("order")
      expect(val).to have_key("width")
      expect(val).to have_key("visibility")
      expect(val).to have_key("filter")
      expect(val).to have_key("sort")
      expect(val).to have_key("columns")
    end

    it "skips records with no order, width, visibility, filter, or sort" do
      state = create_state("some_unrelated_key" => "value")

      migration.up

      val = JSON.parse(state.reload.state_value)
      expect(val).not_to have_key("columns")
    end

    it "migrates a record that only has a filter, with no order/width/visibility" do
      state = create_state("filter" => {"name" => "test"})

      migration.up

      val = JSON.parse(state.reload.state_value)
      expect(val).to have_key("filter")
      expect(val["columns"]).to eq([{"id" => "name", "visible" => true, "filter" => "test"}])
    end

    it "migrates a record that only has a sort, with no order/width/visibility" do
      state = create_state("sort" => {"sortCol" => "created_at", "sortDir" => "1"})

      migration.up

      val = JSON.parse(state.reload.state_value)
      expect(val).to have_key("sort")
      expect(val["columns"]).to eq([{"id" => "created_at", "visible" => true, "sort" => "asc"}])
    end

    it "includes a column referenced only by filter or sort, not by order/width/visibility" do
      state = create_state(
        "order" => {"0" => "name", "1" => "email"},
        "filter" => {"rank" => "10"}
      )

      migration.up

      columns = JSON.parse(state.reload.state_value)["columns"]
      expect(columns.map { |c| c["id"] }).to eq(%w[name email rank])
      expect(columns.find { |c| c["id"] == "rank" }["filter"]).to eq("10")
    end

    it "does not fabricate a sort direction when sortDir is missing" do
      state = create_state(
        "order" => {"0" => "name", "1" => "created_at"},
        "sort" => {"sortCol" => "created_at"}
      )

      migration.up

      columns = JSON.parse(state.reload.state_value)["columns"]
      expect(columns.find { |c| c["id"] == "created_at" }).not_to have_key("sort")
    end
  end

  describe "#down" do
    it "removes columns key and preserves legacy keys" do
      state = create_state(
        "order" => {"0" => "name", "1" => "rank", "2" => "id"},
        "width" => {"name" => 200},
        "visibility" => ["id"],
        "filter" => {"rank" => "10"},
        "sort" => {"sortCol" => "rank", "sortDir" => 1},
        "columns" => [
          {"id" => "name", "visible" => true, "width" => 200},
          {"id" => "rank", "visible" => true, "filter" => "10", "sort" => "asc"},
          {"id" => "id", "visible" => false}
        ]
      )

      migration.down

      val = JSON.parse(state.reload.state_value)
      expect(val).not_to have_key("columns")
      expect(val["order"]).to eq({"0" => "name", "1" => "rank", "2" => "id"})
      expect(val["width"]).to eq({"name" => 200})
      expect(val["visibility"]).to eq(["id"])
      expect(val["filter"]).to eq({"rank" => "10"})
      expect(val["sort"]).to eq({"sortCol" => "rank", "sortDir" => 1})
    end

    it "leaves records with no columns key untouched" do
      state = create_state("order" => {"0" => "name"})

      migration.down

      val = JSON.parse(state.reload.state_value)
      expect(val).to eq("order" => {"0" => "name"})
    end
  end
end
