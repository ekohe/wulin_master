# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_06_15_152900) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "addresses", id: :serial, force: :cascade do |t|
    t.string "country"
    t.string "city"
    t.integer "country_id"
    t.integer "city_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clients", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_clients_on_name"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "courses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "title"
    t.string "desc"
    t.integer "training_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "title"], name: "index_courses_on_name_and_title", unique: true
  end

  create_table "grid_states", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "name", default: "default"
    t.string "grid_name"
    t.text "state_value"
    t.boolean "current", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_grid_states_on_user_id"
  end

  create_table "people", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "birthdate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "job"
    t.boolean "vip", default: false
    t.integer "age", default: 18
    t.text "signature"
    t.integer "status", default: 0
    t.integer "country_id"
    t.integer "training_id"
    t.index ["country_id"], name: "index_people_on_country_id"
    t.index ["training_id"], name: "index_people_on_training_id"
  end

  create_table "people_teachers", id: false, force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "teacher_id", null: false
    t.index ["person_id"], name: "index_people_teachers_on_person_id"
    t.index ["teacher_id"], name: "index_people_teachers_on_teacher_id"
  end

  create_table "posts", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "person_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "students_teachers", id: false, force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "teacher_id", null: false
  end

  create_table "teachers", force: :cascade do |t|
    t.string "name"
    t.string "subject"
  end

  create_table "trainings", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "teacher_id"
    t.integer "client_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
