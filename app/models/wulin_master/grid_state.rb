module WulinMaster 
  class GridState < ::ActiveRecord::Base
    attr_accessible :user_id, :grid_name, :name, :current, :state_value
    
    default_scope :order => 'created_at DESC'
    
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
      if Module.const_defined? :User
        User
      elsif Module.const_defined? :WulinAuth
        WulinAuth::User
      else
        false
      end
    end
    
    def self.current(user_id, grid_name)
      query = for_user_and_grid(user_id, grid_name)
      query.where(:current => true).first || query.where(:name => "default").first || query.first
    end

    # ------------------------------ Instance Methods -------------------------------
    def brother_states
      self.class.for_user_and_grid(self.user_id, self.grid_name).where("id != ?", self.id)
    end

  end
end

if WulinMaster::GridState.user_model
  WulinMaster::GridState.send(:belongs_to, :user, :class_name => WulinMaster::GridState.user_model.name)
  WulinMaster::GridState.user_model.send(:has_many, :grid_states, :class_name => "WulinMaster::GridState") if WulinMaster::GridState.user_model.name == 'WulinAuth::User'
end
