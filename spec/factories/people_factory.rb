# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :person do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    birthdate { Faker::Date.between(from: 100.years.ago, to: 16.years.ago) }
  end
end
