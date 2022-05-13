# frozen_string_literal: true

module WulinMaster
  class GridState < ::ActiveRecord::Base
    cattr_accessor :all_users
    validates :name, uniqueness: {scope: %i[user_id grid_name]}
    validate :valid_json

    scope :for_user_and_grid, ->(user_id, grid_name) { where(user_id: user_id, grid_name: grid_name) }
    scope :user_grid_view_name, ->(user_id, grid_name, name) { where(user_id: user_id, grid_name: grid_name, name: name) }
    scope :default, -> { where(name: 'default') }
    scope :current_ones, -> { where(current: true) }
    scope :default_grid, ->(grid_name) { where(user_id: nil, grid_name: grid_name, name: "default") }
    scope :initial_custom_grid, ->(grid_name, name) { where(user_id: nil, grid_name: grid_name, name: name) }

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
    # ------------------------------ Instance Methods -------------------------------

    def brother_states
      self.class.for_user_and_grid(user_id, grid_name).where("id != ?", id)
    end

    def user
      self.class.all_users ||= User.all
      prepare_user
    end

    def email
      # The user email configured from `app/controllers/wulin_master/grid_states_controller.rb` method `clear_invalid_states_and_users_cache`
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
      self.class.all_users.find { |x| x.id == user_id }
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
