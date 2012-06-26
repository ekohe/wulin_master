module WulinMaster
  module GridStates
    extend ActiveSupport::Concern
    
    # ----------------------------- Instance Methods ------------------------------------
    def states_for_user(user)
      return "false" if user.nil?
      result = {}
      begin
        states = GridState.where(:user_id => user.id, :grid_name => self.name).all
        %w(width sort order visibility filter).each do |t|
          value = states.find{|s| s.state_type == t}.try(:state_value)
          result.merge!(t => ActiveSupport::JSON.decode(value)) if value
        end
        result.to_json
      rescue Exception => e
        Rails.logger.info "Exception thrown while trying to get user states: #{e.inspect}"
        {}.to_json
      end
    end

  end
end

