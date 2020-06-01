# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :posts
  has_and_belongs_to_many :teachers
  belongs_to :country

  enum status: %i[busy avaialbe free]
end
