# frozen_string_literal: true

class Course < ActiveRecord::Base
  belongs_to :training
end
