# frozen_string_literal: true

class Teacher < ApplicationRecord
  has_and_belongs_to_many :students, class_name: 'Person'
  has_many :trainings
  # can not edit, can not sort
  # need to be fixed
  # has_many :training_students, through: :trainings, source: :students
  has_many :courses, through: :trainings
  has_many :clients, through: :trainings
end
