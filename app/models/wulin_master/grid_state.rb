module WulinMaster 
  class GridState < ::ActiveRecord::Base
    default_scope :order => 'created_at DESC'

    if defined? WulinAuth
      belongs_to :user, :class_name => "WulinAuth::User"
    else
      raise 'WulinAuth is missing! wulin_master gem is dependence on wulin_auth; Put "gem wulin_auth" to your Gemfile and run "bundle install --path bundle" command.'
    end

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

if defined? WulinAuth
  WulinAuth::User.send(:has_many, :grid_states, :class_name => "WulinMaster::GridState")
else
  raise 'WulinAuth is missing! wulin_master gem is dependence on wulin_auth; Put "gem wulin_auth" to your Gemfile and run "bundle install --path bundle" command.'
end