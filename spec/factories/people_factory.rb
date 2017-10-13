# frozen_string_literal: true

require 'faker'

FactoryGirl.define do
  factory :person do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthdate { Faker::Date.between(100.years.ago, 16.years.ago) }
  end
end
