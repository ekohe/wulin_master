# frozen_string_literal: true

module WulinMaster
  class GridState < ::ActiveRecord::Base
    cattr_accessor :all_users
    validates :name, uniqueness: {scope: %i[user_id grid_name]}

    scope :for_user_and_grid, ->(user_id, grid_name) { where(user_id: user_id, grid_name: grid_name) }
    scope :default, -> { where(name: 'default') }

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
      states = for_user_and_grid(user_id, grid_name).all
      return nil if states.blank?

      states.find(&:current?) || states.find { |x| x.name.to_s.casecmp('default').zero? } || states.first
    end

    def self.create_default(user_id, grid_name)
      grid_state = WulinMaster::GridState.for_user_and_grid(user_id, grid_name).first
      return grid_state if grid_state.present?
      create(grid_name: grid_name, user_id: user_id, current: true)
    end

    # cache all_users, loop all states and destroy the state without valid user_id
    def self.clear_invalid_states!
      return if all_users.blank?

      all.find_each do |state|
        state.destroy unless all_users.map(&:id).include?(state.user_id)
      end
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
      user.try(:email)
    end

    def reset!
      update!(state_value: nil)
    end

    private

    def prepare_user
      self.class.all_users.find { |x| x.id == user_id }
    end

    def grid_state_params
      params.require(:grid_state).permit(:user_id, :grid_name, :name, :current, :state_value)
    end
  end
end

if WulinMaster::GridState.user_model
  WulinMaster::GridState.send(:belongs_to, :user, class_name: WulinMaster::GridState.user_model.name)
  if WulinMaster::GridState.user_model.name == 'WulinAuth::User'
    WulinMaster::GridState.user_model.send(:has_many, :grid_states, class_name: "WulinMaster::GridState")
  end
end
