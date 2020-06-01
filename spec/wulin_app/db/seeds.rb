# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

JOBS = %w[Developer DevOps Designer PM].freeze

COUNTRIES = %w[China America France].freeze

COUNTRIES.each do |country_name|
  Country.create(name: country_name)
end

SUBJECTS_WITH_TEACHER_NAMES = {
  math: 'Mike',
  english: 'Jack',
  history: 'Tom'
}.freeze

SUBJECTS_WITH_TEACHER_NAMES.each do |subject, name|
  Teacher.create(subject: subject, name: name)
end

teachers = Teacher.all

1.upto(500) do |index|
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

  person.save
end
