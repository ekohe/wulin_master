# frozen_string_literal: true

class Post < ApplicationRecord
  belongs_to :person
  has_one :country, through: :person
  delegate :job, to: :person, prefix: true, allow_nil: true

  delegate :name, to: :country, prefix: true, allow_nil: true
end
