# frozen_string_literal: true

class Teacher < ApplicationRecord
  has_and_belongs_to_many :students, class_name: 'Person'
end
