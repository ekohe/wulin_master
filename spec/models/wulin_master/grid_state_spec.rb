# frozen_string_literal: true

require "rails_helper"

# Test MenuEntry
describe WulinMaster::GridState do
  context "::create_default" do
    it "create one if not exist" do
      user_id = 1
      grid_name = "sonar_next_entity_in_entity"
      grid_state = WulinMaster::GridState.create_default(user_id, grid_name)
      expect(grid_state.class).to eql(WulinMaster::GridState)
    end

    it "return the first one if exist" do
      user_id = 1
      grid_name = "sonar_next_entity_in_entity"
      grid_state1 = WulinMaster::GridState.create_default(user_id, grid_name)
      grid_state2 = WulinMaster::GridState.create_default(user_id, grid_name)
      expect(grid_state1).to eql(grid_state2)
    end
  end

  describe "::convert_old_format" do
    def converted(val)
      JSON.parse(WulinMaster::GridState.convert_old_format(val.to_json))
    end

    it "builds columns from order, width, and hidden ids" do
      result = converted(
        "order" => {"0" => "name", "1" => "email", "2" => "id"},
        "width" => {"name" => 200, "email" => "300"},
        "visibility" => ["id"]
      )

      expect(result["columns"]).to eq([
        {"id" => "name", "visible" => true, "width" => 200},
        {"id" => "email", "visible" => true, "width" => 300},
        {"id" => "id", "visible" => false}
      ])
    end

    it "hides columns listed in visibility and ignores width-only columns" do
      result = converted(
        "order" => {"0" => "code", "1" => "person_last_name"},
        "visibility" => ["job_title_code"],
        "width" => {"code" => "188", "id" => "150"},
        "filter" => {"person_last_name" => "brisson"},
        "sort" => {"sortCol" => "code", "sortDir" => "1"}
      )

      expect(result["columns"]).to eq([
        {"id" => "code", "visible" => true, "width" => 188, "sort" => "asc"},
        {"id" => "person_last_name", "visible" => true, "filter" => "brisson"},
        {"id" => "job_title_code", "visible" => false}
      ])
    end

    it "appends columns that only appear in filter or sort and keeps pinned columns" do
      result = converted(
        "order" => {"0" => "name"},
        "filter" => {"rank" => "10", "city" => ""},
        "sort" => {"sortCol" => "created_at", "sortDir" => -1},
        "pinnedColumns" => ["name"]
      )

      expect(result["columns"]).to eq([
        {"id" => "name", "visible" => true},
        {"id" => "rank", "visible" => true, "filter" => "10"},
        {"id" => "created_at", "visible" => true, "sort" => "desc"}
      ])
      expect(result["pinnedColumns"]).to eq(["name"])
    end

    it "keeps a state that is already in the current format" do
      columns = [{"id" => "name", "visible" => true}]

      expect(converted("columns" => columns)).to eq("columns" => columns)
    end

    it "rejects JSON that has no columns to import" do
      expect { WulinMaster::GridState.convert_old_format("{}") }
        .to raise_error(ArgumentError, "Could not read columns from the old format state value")
    end

    it "rejects invalid JSON" do
      expect { WulinMaster::GridState.convert_old_format("not json") }
        .to raise_error(ArgumentError, "Invalid JSON")
    end
  end
end
