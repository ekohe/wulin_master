# frozen_string_literal: true

require "spec_helper"
require "./lib/wulin_master/components/component"
require "./lib/wulin_master/components/grid/grid"
require "./lib/wulin_master/components/grid/grid_options"

describe WulinMaster::GridOptions do
  it "should return 60 as custom row height" do
    class PostGrid < WulinMaster::Grid
      row_height 60
    end
    options = PostGrid.options_pool.reduce({}) { |h, v| h.merge v }

    expect(options[:rowHeight]).to eq(60)
  end

  # cell_editable (Grid-level) - 3 tests
  describe "cell_editable in options_pool" do
    it "not_set: defaults to true" do
      class CellEditableNotSetGrid < WulinMaster::Grid
      end
      options = CellEditableNotSetGrid.options_pool.reduce({}) { |h, v| h.merge v }
      expect(options[:editable]).to eq(true)
    end

    it "true: editable is true" do
      class CellEditableTrueGrid < WulinMaster::Grid
        cell_editable true
      end
      options = CellEditableTrueGrid.options_pool.reduce({}) { |h, v| h.merge v }
      expect(options[:editable]).to eq(true)
    end

    it "false: editable is false" do
      class CellEditableFalseGrid < WulinMaster::Grid
        cell_editable false
      end
      options = CellEditableFalseGrid.options_pool.reduce({}) { |h, v| h.merge v }
      expect(options[:editable]).to eq(false)
    end
  end

  # editable (Column-level in columns_pool) - 3 tests
  describe "editable in columns_pool" do
    it "not_set: column does not have editable option" do
      class EditableNotSetGrid < WulinMaster::Grid
        column :title
      end
      column = EditableNotSetGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options).not_to have_key("editable")
    end

    it "true: column has editable true" do
      class EditableTrueGrid < WulinMaster::Grid
        column :title, editable: true
      end
      column = EditableTrueGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["editable"]).to eq(true)
    end

    it "false: column has editable false" do
      class EditableFalseGrid < WulinMaster::Grid
        column :title, editable: false
      end
      column = EditableFalseGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["editable"]).to eq(false)
    end
  end

  # visible (Column-level in columns_pool) - 3 tests
  describe "visible in columns_pool" do
    it "not_set: column does not have visible option" do
      class VisibleNotSetGrid < WulinMaster::Grid
        column :title
      end
      column = VisibleNotSetGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options).not_to have_key("visible")
    end

    it "true: column has visible true" do
      class VisibleTrueGrid < WulinMaster::Grid
        column :title, visible: true
      end
      column = VisibleTrueGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["visible"]).to eq(true)
    end

    it "false: column has visible false" do
      class VisibleFalseGrid < WulinMaster::Grid
        column :title, visible: false
      end
      column = VisibleFalseGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["visible"]).to eq(false)
    end
  end

  # formable (Column-level in columns_pool) - 3 tests
  describe "formable in columns_pool" do
    it "not_set: column does not have formable option" do
      class FormableNotSetGrid < WulinMaster::Grid
        column :title
      end
      column = FormableNotSetGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options).not_to have_key("formable")
    end

    it "true: column has formable true" do
      class FormableTrueGrid < WulinMaster::Grid
        column :title, formable: true
      end
      column = FormableTrueGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["formable"]).to eq(true)
    end

    it "false: column has formable false" do
      class FormableFalseGrid < WulinMaster::Grid
        column :title, formable: false
      end
      column = FormableFalseGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["formable"]).to eq(false)
    end
  end

  # Proc support for visible option
  describe "visible with Proc in columns_pool" do
    it "proc returning true: column has visible as Proc" do
      class VisibleProcTrueGrid < WulinMaster::Grid
        column :title, visible: proc { true }
      end
      column = VisibleProcTrueGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["visible"]).to be_a(Proc)
      expect(column.options["visible"].call).to eq(true)
    end

    it "proc returning false: column has visible as Proc" do
      class VisibleProcFalseGrid < WulinMaster::Grid
        column :title, visible: proc { false }
      end
      column = VisibleProcFalseGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["visible"]).to be_a(Proc)
      expect(column.options["visible"].call).to eq(false)
    end

    it "proc with dynamic condition" do
      condition = true
      class VisibleProcDynamicGrid < WulinMaster::Grid
        column :title, visible: proc { condition }
      end
      column = VisibleProcDynamicGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["visible"]).to be_a(Proc)
    end
  end

  # Proc support for editable option
  describe "editable with Proc in columns_pool" do
    it "proc returning true: column has editable as Proc" do
      class EditableProcTrueGrid < WulinMaster::Grid
        column :title, editable: proc { true }
      end
      column = EditableProcTrueGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["editable"]).to be_a(Proc)
      expect(column.options["editable"].call).to eq(true)
    end

    it "proc returning false: column has editable as Proc" do
      class EditableProcFalseGrid < WulinMaster::Grid
        column :title, editable: proc { false }
      end
      column = EditableProcFalseGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["editable"]).to be_a(Proc)
      expect(column.options["editable"].call).to eq(false)
    end

    it "proc with dynamic condition" do
      is_admin = false
      class EditableProcDynamicGrid < WulinMaster::Grid
        column :title, editable: proc { is_admin }
      end
      column = EditableProcDynamicGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["editable"]).to be_a(Proc)
    end
  end

  # Proc support for formable option
  describe "formable with Proc in columns_pool" do
    it "proc returning true: column has formable as Proc" do
      class FormableProcTrueGrid < WulinMaster::Grid
        column :title, formable: proc { true }
      end
      column = FormableProcTrueGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["formable"]).to be_a(Proc)
      expect(column.options["formable"].call).to eq(true)
    end

    it "proc returning false: column has formable as Proc" do
      class FormableProcFalseGrid < WulinMaster::Grid
        column :title, formable: proc { false }
      end
      column = FormableProcFalseGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["formable"]).to be_a(Proc)
      expect(column.options["formable"].call).to eq(false)
    end

    it "proc returning [:new]: column has formable as Proc returning array" do
      class FormableProcNewGrid < WulinMaster::Grid
        column :title, formable: proc { [:new] }
      end
      column = FormableProcNewGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["formable"]).to be_a(Proc)
      expect(column.options["formable"].call).to eq([:new])
    end

    it "proc returning [:edit]: column has formable as Proc returning array" do
      class FormableProcEditGrid < WulinMaster::Grid
        column :title, formable: proc { [:edit] }
      end
      column = FormableProcEditGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["formable"]).to be_a(Proc)
      expect(column.options["formable"].call).to eq([:edit])
    end

    it "proc returning [:new, :edit]: column has formable as Proc returning array" do
      class FormableProcNewEditGrid < WulinMaster::Grid
        column :title, formable: proc { [:new, :edit] }
      end
      column = FormableProcNewEditGrid.columns_pool.find { |c| c.name == :title }
      expect(column.options["formable"]).to be_a(Proc)
      expect(column.options["formable"].call).to eq([:new, :edit])
    end
  end

  # Combinations: cell_editable × editable × visible × formable (81 tests)
  describe "cell_editable, editable, visible, formable combinations" do
    CELL_EDITABLE_OPTIONS = [nil, true, false].freeze
    EDITABLE_OPTIONS = [nil, true, false].freeze
    VISIBLE_OPTIONS = [nil, true, false].freeze
    FORMABLE_OPTIONS = [nil, true, false].freeze

    test_index = 0
    CELL_EDITABLE_OPTIONS.each do |cell_editable_val|
      EDITABLE_OPTIONS.each do |editable_val|
        VISIBLE_OPTIONS.each do |visible_val|
          FORMABLE_OPTIONS.each do |formable_val|
            test_index += 1
            current_index = test_index

            cell_editable_desc = cell_editable_val.nil? ? "nil" : cell_editable_val.to_s
            editable_desc = editable_val.nil? ? "nil" : editable_val.to_s
            visible_desc = visible_val.nil? ? "nil" : visible_val.to_s
            formable_desc = formable_val.nil? ? "nil" : formable_val.to_s

            it "cell_editable(#{cell_editable_desc}) + editable(#{editable_desc}) + visible(#{visible_desc}) + formable(#{formable_desc})" do
              # Build grid class dynamically
              class_name = "ComboGrid#{current_index}"
              Object.send(:remove_const, class_name) if Object.const_defined?(class_name)

              grid_class = Class.new(WulinMaster::Grid)
              Object.const_set(class_name, grid_class)

              # Set cell_editable (grid-level)
              case cell_editable_val
              when true
                grid_class.cell_editable true
              when false
                grid_class.cell_editable false
              end

              # Build column options
              column_opts = {}
              column_opts[:editable] = editable_val unless editable_val.nil?
              column_opts[:visible] = visible_val unless visible_val.nil?
              column_opts[:formable] = formable_val unless formable_val.nil?

              # Add column to grid
              grid_class.column :title, column_opts

              # Get grid options_pool
              grid_options = grid_class.options_pool.reduce({}) { |h, v| h.merge v }

              # Get column from columns_pool
              column = grid_class.columns_pool.find { |c| c.name == :title }

              # Verify grid-level cell_editable
              expected_cell_editable = cell_editable_val == false ? false : true
              expect(grid_options[:editable]).to eq(expected_cell_editable)

              # Verify column-level editable
              if editable_val.nil?
                expect(column.options).not_to have_key("editable")
              else
                expect(column.options["editable"]).to eq(editable_val)
              end

              # Verify column-level visible
              if visible_val.nil?
                expect(column.options).not_to have_key("visible")
              else
                expect(column.options["visible"]).to eq(visible_val)
              end

              # Verify column-level formable
              if formable_val.nil?
                expect(column.options).not_to have_key("formable")
              else
                expect(column.options["formable"]).to eq(formable_val)
              end
            end
          end
        end
      end
    end
  end
end
