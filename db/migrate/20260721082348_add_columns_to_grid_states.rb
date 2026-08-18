# frozen_string_literal: true

# Adds a unified "columns" key to grid_states.state_value alongside the existing
# order/width/visibility/filter/sort keys (which are preserved for backward
# compatibility). The "columns" array carries order (by position), width,
# visibility, filter, and sort per column. New columns not in the array fall
# back to their grid definition — fixing the bug where visible: false columns
# appeared visible for users with a saved grid state.
#
# See: https://gitlab.ekohe.com/ekohe/wulin/wulin_master/-/work_items/290
class AddColumnsToGridStates < ActiveRecord::Migration[5.0]
  def up
    WulinMaster::GridState.find_each do |state|
      next if state.state_value.blank?

      begin
        val = JSON.parse(state.state_value)
      rescue JSON::ParserError
        next
      end
      next unless val.is_a?(Hash)

      order      = val["order"]
      width      = val["width"]
      visibility = val["visibility"]
      filter     = val["filter"]
      sort       = val["sort"]

      next if order.nil? && width.nil? && visibility.nil? && filter.nil? && sort.nil?

      ordered_ids = if order.is_a?(Hash)
        order.sort_by { |k, _| k.to_i }.map(&:last)
      else
        []
      end

      hidden_ids = Set.new(Array(visibility))
      extra_ids = (
        (width.is_a?(Hash) ? width.keys : []) +
        Array(visibility) +
        (filter.is_a?(Hash) ? filter.keys : []) +
        (sort.is_a?(Hash) && sort["sortCol"] ? [sort["sortCol"]] : [])
      ) - ordered_ids
      all_ids = ordered_ids + extra_ids.uniq

      columns = all_ids.map do |id|
        entry = {"id" => id, "visible" => !hidden_ids.include?(id)}
        entry["width"] = width[id].to_i if width.is_a?(Hash) && width.key?(id)
        entry["filter"] = filter[id] if filter.is_a?(Hash) && filter.key?(id)
        if sort.is_a?(Hash) && sort["sortCol"] == id && sort["sortDir"].present?
          entry["sort"] = sort["sortDir"].to_i == 1 ? "asc" : "desc"
        end
        entry
      end

      next if columns.empty?

      val["columns"] = columns
      state.update_column(:state_value, val.to_json)
    end
  end

  def down
    WulinMaster::GridState.find_each do |state|
      next if state.state_value.blank?

      begin
        val = JSON.parse(state.state_value)
      rescue JSON::ParserError
        next
      end
      next unless val.is_a?(Hash) && val.key?("columns")

      val.delete("columns")
      state.update_column(:state_value, val.to_json)
    end
  end
end
