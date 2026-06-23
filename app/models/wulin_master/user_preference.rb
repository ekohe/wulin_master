# frozen_string_literal: true

module WulinMaster
  class UserPreference < ::ActiveRecord::Base
    self.table_name = "user_preferences"

    validates :name, presence: true, uniqueness: {scope: :user_id}

    reject_audit if defined? ::WulinAudit
  end
end
