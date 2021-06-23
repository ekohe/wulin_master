# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :posts
  belongs_to :country
  belongs_to :training
  has_and_belongs_to_many :teachers

  delegate :name, to: :country, prefix: true, allow_nil: true

  enum status: %i[busy avaialbe free]

  def name
    first_name
  end
end
