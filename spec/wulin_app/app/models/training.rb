# frozen_string_literal: true

class Training < ActiveRecord::Base
  belongs_to :teacher
  belongs_to :client
  has_many :students, class_name: 'Person'
  has_many :courses
end
