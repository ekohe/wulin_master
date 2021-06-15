# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

JOBS = %w[Developer DevOps Designer PM].freeze
TRAINING_NAME = %w[I hope that a study of very long sentences will arm you with strategies are almost as diverse the themselves]
COUNTRIES = %w[China America France].freeze
FIRST_NAMES = %w[hello ruby world].repeated_combination(3).map do |cb|
  cb.uniq.join(' ')
end

COUNTRIES.each do |country_name|
  Country.create(name: country_name)
end

FIRST_NAMES.each do |name|
  Teacher.create(subject: name, name: name)
end

FIRST_NAMES.each do |name|
  Client.create(name: name)
end

TRAINING_NAME.each do |name|
  Training.create(name: name, teacher: Teacher.all.sample, client: Client.all.sample)
end

FIRST_NAMES.each do |name|
  Course.create(name: name, training: Training.all.sample)
end

teachers = Teacher.all

FIRST_NAMES.each_with_index do |name, index|
  person = Person.new(
    first_name: name,
    last_name: "last name #{sprintf('%04d', index)}",
    job: JOBS.sample,
    status: Person.statuses.values.sample,
    vip: [true, false].sample,
    birthdate: Date.today,
    age: (15..40).to_a.sample,
    signature: "wulin_master is a powerful ruby gem"
  )

  person.teachers = teachers
  person.country = Country.all.sample
  person.training = Training.all.sample

  person.posts.build(name: "A post about #{name}")

  person.save
end

7.upto(500) do |index|
  person = Person.new(
    first_name: "first name #{sprintf('%04d', index)}",
    last_name: "last name #{sprintf('%04d', index)}",
    job: JOBS.sample,
    status: Person.statuses.values.sample,
    vip: [true, false].sample,
    birthdate: Date.today,
    age: (15..40).to_a.sample,
    signature: "wulin_master is a powerful ruby gem"
  )

  person.teachers = teachers
  person.country = Country.all.sample

  person.posts.build(name: "A post about #{JOBS.sample}")

  person.save
end
