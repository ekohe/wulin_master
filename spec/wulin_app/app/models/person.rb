# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :posts

  enum status: %i[busy avaialbe free]
end
