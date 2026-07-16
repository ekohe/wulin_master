# frozen_string_literal: true

require "spec_helper"
require "./lib/wulin_master/components/grid/column"

describe WulinMaster::Column do
  before :each do
    @grid = double(:grid)
    @model = double(:model)
    allow(@grid).to receive(:model) { @model }
    @column = WulinMaster::Column.new(:title, @grid)
  end

  it "should have a symbol name" do
    column = WulinMaster::Column.new("name", @grid)
    expect(column.name).to eq(:name)
  end

  it "should have default options" do
    expect(@column.options).to eq("width" => 150, "sortable" => true, "default_sort_asc" => true)
  end

  it "can have customized options" do
    @column = WulinMaster::Column.new(:title, @grid, width: 100, editable: false, label: "Title")
    expect(@column.options).to eq("width" => 100, "sortable" => true, "editable" => false, "default_sort_asc" => true, "label" => "Title")
  end

  it "should have a default label from the localization file" do
    expect(@model).to receive(:human_attribute_name) { "Human title" }
    expect(@column.label).to eq("Human title")
  end

  it "can have customized label" do
    @column = WulinMaster::Column.new(:title, @grid, label: "Post Title")
    expect(@column.label).to eq("Post Title")
  end

  it "formats datetime values in the configured time zone without a zone suffix" do
    column = WulinMaster::Column.new(
      :created_at,
      @grid,
      type: "Datetime",
      datetime_format: :with_seconds,
      time_zone: "UTC"
    )
    allow(column).to receive(:sql_type).and_return(:datetime)
    value = ActiveSupport::TimeZone["America/New_York"].local(2026, 7, 13, 7, 59, 11)

    expect(column.format(value)).to eq("13/07/2026 11:59:11")
    expect(column.format(value)).not_to match(/UTC|[-+]\d{4}/)
  end

  it "formats local datetime values without an offset suffix" do
    column = WulinMaster::Column.new(
      :created_at_local,
      @grid,
      type: "Datetime",
      datetime_format: :with_seconds
    )
    allow(column).to receive(:sql_type).and_return(:datetime)
    value = ActiveSupport::TimeZone["America/New_York"].local(2026, 7, 13, 7, 59, 11)

    expect(column.format(value)).to eq("13/07/2026 07:59:11")
    expect(column.format(value)).not_to match(/UTC|[-+]\d{4}/)
  end
end
