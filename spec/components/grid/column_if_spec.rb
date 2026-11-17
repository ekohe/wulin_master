# frozen_string_literal: true

require "rails_helper"

class ColumnIfGrid < WulinMaster::Grid
  cattr_accessor :show_last_name

  model Person

  column :first_name
  column :last_name, if: -> { ColumnIfGrid.show_last_name }
  column :age, if: false
end

RSpec.describe WulinMaster::Column, "if: option" do
  def grid_for(params)
    ColumnIfGrid.new(double(params: ActionController::Parameters.new(params), controller: nil, current_user: nil))
  end

  def column_names(grid)
    grid.columns.map(&:name)
  end

  ["PeopleScreen", nil].each do |screen|
    context "with screen #{screen.inspect}" do
      let(:grid) { grid_for(screen: screen) }

      it "leaves a column out of the grid when its proc returns false" do
        ColumnIfGrid.show_last_name = false

        expect(column_names(grid)).to eq([:id, :first_name])
        expect(JSON.parse(grid.javascript_column_model).map { |c| c["column_name"] }).to eq(%w[id first_name])
      end

      it "keeps a column in the grid when its proc returns true" do
        ColumnIfGrid.show_last_name = true

        expect(column_names(grid)).to eq([:id, :first_name, :last_name])
      end

      it "calls the proc on each call" do
        ColumnIfGrid.show_last_name = false
        expect(column_names(grid)).not_to include(:last_name)

        ColumnIfGrid.show_last_name = true
        expect(column_names(grid)).to include(:last_name)
      end
    end
  end
end
