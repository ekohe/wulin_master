if defined? WulinAuth
  module WulinMaster 
    class GridState < ::ActiveRecord::Base
      default_scope :order => 'created_at DESC'

      belongs_to :user, :class_name => "WulinAuth::User"

      def self.update_or_create(attrs)
        attrs_dup = attrs.dup
        state_value = attrs_dup.delete(:state_value)
        if state = where(attrs_dup).first
          state.update_attribute(:state_value, state_value)
        else
          create(attrs)
        end
      end
    
    end
  end
  
  WulinAuth::User.send(:has_many, :grid_states, :class_name => "WulinMaster::GridState")
end

# WulinAuth::User.send(:has_many, :grid_states, :class_name => "WulinMaster::GridState") if defined? WulinAuth