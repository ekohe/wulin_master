# frozen_string_literal: true

require "rails_helper"

RSpec.describe WulinMaster::Column, "#reflection" do
  it "returns nil for a column without association and looks the reflections up once" do
    column = described_class.new(:first_name, PersonGrid)

    expect(Person).to receive(:reflections).once.and_call_original

    expect(Array.new(3) { column.reflection }).to eq([nil, nil, nil])
  end

  it "returns the same reflection for an association column" do
    column = described_class.new(:teachers, PersonGrid)

    expect(column.reflection).to be_a(ActiveRecord::Reflection::AbstractReflection)
    expect(column.reflection).to equal(column.reflection)
    expect(column.reflection.name).to eq(:teachers)
  end
end
