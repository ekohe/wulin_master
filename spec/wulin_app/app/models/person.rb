# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :posts
  has_and_belongs_to_many :teachers

  enum status: %i[busy avaialbe free]
end
