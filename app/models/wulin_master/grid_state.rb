# frozen_string_literal: true

module WulinMaster
  class GridState < ::ActiveRecord::Base
    cattr_accessor :all_users
    validates :name, uniqueness: {scope: %i[user_id grid_name]}
    validate :valid_json

    scope :for_user_and_grid, ->(user_id, grid_name) { where(user_id: user_id, grid_name: grid_name) }
    scope :default, -> { where(name: 'default') }
    scope :current_ones, -> { where(current: true) }
    scope :default_grid, ->(grid_name) { where(user_id: nil, grid_name: grid_name, name: "default") }
    scope :initial_custom_grid, ->(grid_name, name) { where(user_id: nil, grid_name: grid_name, name: name) }
    scope :multiple_grid_states, ->(grid_name) { where(user_id: nil, grid_name: grid_name) }

    reject_audit if defined? ::WulinAudit

    def self.update_or_create(attrs)
      attrs_dup = attrs.dup
      state_value = attrs_dup.delete(:state_value)
      if state = find_by(attrs_dup)
        if state_value.match?(/^\s*(null|undefined)\s*$/)
          state.destroy
        else
          state.update(:state_value, state_value)
        end
      elsif !state_value.match?(/^\s*(null|undefined)\s*$/)
        create(attrs)
      end
    end

    def self.user_model
      if Module.const_defined? :WulinAuth
        WulinAuth::User
      elsif Module.const_defined? :User
        User
      else
        false
      end
    end

    def self.current(user_id, grid_name)
      states = for_user_and_grid(user_id, grid_name)
      return nil if states.blank?
      states.current_ones.first || states.find { |x| x.name.to_s.casecmp('default').zero? } || states.first
    end

    def self.create_default(user_id, grid_name)
      grid_state = for_user_and_grid(user_id, grid_name)

      grid_state_names = grid_state.pluck(:name)
      multiple_grid_states(grid_name).each do |state|
        next if grid_state_names.include? state.name
        new_state = state.dup
        new_state.user_id = user_id
        new_state.current = false
        new_state.save
      end

      return grid_state.first if grid_state.present?
      grid_state.current_ones.create
    end

    def self.current_or_default(user_id, grid_name)
      current(user_id, grid_name) || create_default(user_id, grid_name)
    end

    def self.get_default_grid_state_val(grid_name, name=false, is_custom_view=false)
      default_grids = is_custom_view ? initial_custom_grid(grid_name, name).first : default_grid(grid_name).first
      return default_grids.try(:state_value).blank? ? nil : default_grids.state_value
    end

    # Previous events stored column order, width, hidden ids, filter, and sort as
    # separate keys. The grid now reads a single columns array.
    def self.convert_old_format(raw)
      val = JSON.parse(raw.to_s)
      raise ArgumentError, "State value must be a JSON object" unless val.is_a?(Hash)

      columns = if val["columns"].is_a?(Array)
        val["columns"]
      elsif legacy_format?(val)
        unified_columns(val)
      end
      raise ArgumentError, "Could not read columns from the old format state value" unless columns.is_a?(Array) && columns.any?

      result = {"columns" => columns}
      result["pinnedColumns"] = val["pinnedColumns"] if val["pinnedColumns"].is_a?(Array)
      result.to_json
    rescue JSON::ParserError
      raise ArgumentError, "Invalid JSON"
    end

    def self.legacy_format?(val)
      %w[order width visibility filter sort].any? { |key| val.key?(key) }
    end
    private_class_method :legacy_format?

    # "order" is the visible sequence (index => column id). "visibility" lists
    # hidden ids, which are kept in the array so they stay hidden. Width is
    # applied to those columns only — a width entry alone is the default width
    # of a column the view did not include.
    def self.unified_columns(val)
      order, width, visibility, filter, sort = val.values_at("order", "width", "visibility", "filter", "sort")
      ordered_ids = order.is_a?(Hash) ? order.sort_by { |k, _| k.to_i }.map(&:last) : []
      extra_ids = (
        Array(visibility) +
        (filter.is_a?(Hash) ? filter.select { |_, value| value.present? }.keys : []) +
        (sort.is_a?(Hash) && sort["sortCol"] ? [sort["sortCol"]] : [])
      ) - ordered_ids
      hidden_ids = Array(visibility)

      (ordered_ids + extra_ids.uniq).filter_map do |id|
        next unless id.is_a?(String)

        entry = {"id" => id, "visible" => !hidden_ids.include?(id)}
        entry["width"] = width[id].to_i if width.is_a?(Hash) && width.key?(id)
        entry["filter"] = filter[id] if filter.is_a?(Hash) && filter.key?(id) && filter[id].present?
        if sort.is_a?(Hash) && sort["sortCol"] == id && sort["sortDir"].present?
          entry["sort"] = sort["sortDir"].to_i == 1 ? "asc" : "desc"
        end
        entry
      end
    end
    private_class_method :unified_columns
    # ------------------------------ Instance Methods -------------------------------

    def brother_states
      self.class.for_user_and_grid(user_id, grid_name).where("id != ?", id)
    end

    def user
      self.class.all_users ||= User.all
      prepare_user
    end

    def email
      user.try(:email)
    end

    def reset!
      update!(state_value: nil)
    end

    private

    def valid_json
      return unless state_value.present?
      begin
        JSON.parse state_value
      rescue JSON::ParserError => e
        errors.add(:base, "invalid json format")
      end
    end

    def prepare_user
      return if user_id.blank?

      self.class.all_users.find { |x| x.id.to_i == user_id.to_i }
    end

    def grid_state_params
      params.require(:grid_state).permit(:user_id, :grid_name, :name, :current, :state_value)
    end
  end
end

if WulinMaster::GridState.user_model
  WulinMaster::GridState.send(:belongs_to, :user, class_name: WulinMaster::GridState.user_model.name, optional: true)
  if WulinMaster::GridState.user_model.name == 'WulinAuth::User'
    WulinMaster::GridState.user_model.send(:has_many, :grid_states, class_name: "WulinMaster::GridState")
  end
end
