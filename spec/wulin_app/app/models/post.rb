# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :person
  delegate :job, to: :person, prefix: true, allow_nil: true
end
