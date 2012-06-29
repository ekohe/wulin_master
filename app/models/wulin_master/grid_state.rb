module WulinMaster 
  class GridState < ::ActiveRecord::Base
    default_scope :order => 'created_at DESC'
    reject_audit if defined? ::WulinAudit

    def self.update_or_create(attrs)
      attrs_dup = attrs.dup
      state_value = attrs_dup.delete(:state_value)
      if state = where(attrs_dup).first
        if state_value =~ /^\s*(null|undefined)\s*$/
          state.destroy
        else
          state.update_attribute(:state_value, state_value)
        end
      elsif state_value !~ /^\s*(null|undefined)\s*$/
        create(attrs)
      end
    end

    def self.user_model
      if Module.const_defined? :User
        User
      elsif Module.const_defined? :WulinAuth
        WulinAuth::User
      else
        false
      end
    end

  end
end

if WulinMaster::GridState.user_model
  WulinMaster::GridState.send(:belongs_to, :user, :class_name => WulinMaster::GridState.user_model.name)
  WulinMaster::GridState.user_model.send(:has_many, :grid_states, :class_name => "WulinMaster::GridState") if WulinMaster::GridState.user_model.name == 'WulinAuth::User'
end
