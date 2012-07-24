module WulinMaster 
  class GridState < ::ActiveRecord::Base
    attr_accessible :user_id, :grid_name, :state_type, :state_value
    
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

    # State
    def states_for_user(user)
      return "false" if user.nil?
      result = {}
      begin
        states = GridState.where(:user_id => user.id, :grid_name => self.name).all
        %w(width sort order visibility filter).each do |t|
          value = states.find{|s| s.state_type == t}.try(:state_value)
          result.merge!(t => ActiveSupport::JSON.decode(value)) if (value and value !~ /^\s*(null|undefined)\s*$/)
        end
        result.to_json
      rescue Exception => e
        Rails.logger.info "Exception thrown while trying to get user states: #{e.inspect}"
        {}.to_json
      end
    end

  end
end

if WulinMaster::GridState.user_model
  WulinMaster::GridState.send(:belongs_to, :user, :class_name => WulinMaster::GridState.user_model.name)
  WulinMaster::GridState.user_model.send(:has_many, :grid_states, :class_name => "WulinMaster::GridState") if WulinMaster::GridState.user_model.name == 'WulinAuth::User'
end
