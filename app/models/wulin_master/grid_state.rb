module WulinMaster 
  class GridState < ::ActiveRecord::Base
    attr_accessible :user_id, :grid_name, :name, :current, :state_value
    validates :name, :uniqueness => {:scope => [:user_id, :grid_name]}
    
    scope :for_user_and_grid, lambda {|user_id, grid_name| where(:user_id => user_id, :grid_name => grid_name)}
    
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
      states.find{|x| x.current?} || states.find{|x| x.name.to_s.downcase == 'default'} || states.first
    end

    def self.create_default(user_id, grid_name)
      if WulinMaster::GridState.for_user_and_grid(user_id, grid_name).blank?
        create(grid_name: grid_name, user_id: user_id, current: true)
      end
    end

    # ------------------------------ Instance Methods -------------------------------
    def brother_states
      self.class.for_user_and_grid(self.user_id, self.grid_name).where("id != ?", self.id)
    end

    def user
      User.all.find {|u| u.id == user_id}
    end

    def email
      user.try(:email)
    end

  end
end

if WulinMaster::GridState.user_model
  WulinMaster::GridState.send(:belongs_to, :user, :class_name => WulinMaster::GridState.user_model.name)
  WulinMaster::GridState.user_model.send(:has_many, :grid_states, :class_name => "WulinMaster::GridState") if WulinMaster::GridState.user_model.name == 'WulinAuth::User'
end
