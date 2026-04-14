# frozen_string_literal: true

require "rails_helper"

RSpec.describe WulinMaster::ColumnFilter, "multi-valued association filtering" do
  def build_grid(screen_class, grid_class)
    params = ActionController::Parameters.new(screen: screen_class.name, grid: grid_class.name, format: :json)
    controller = double("controller", params: params, current_user: nil)

    screen_class.new(controller).grids.find { |grid| grid.instance_of?(grid_class) }
  end

  def apply_grid_includes(query, grid)
    includes = grid.includes
    return query if includes.empty?

    query.includes(includes).references(includes)
  end

  describe "#apply_filter SQL" do
    it "uses a parent-id subquery for HABTM filters" do
      column = WulinMaster::Column.new(:teachers, PersonGrid)

      sql = column.apply_filter(Person, "Alpha", "equals").to_sql

      expect(sql).to include('"people"."id" IN (SELECT DISTINCT "people"."id"')
      expect(sql).to include('INNER JOIN "people_teachers"')
      expect(sql).to include('INNER JOIN "teachers"')
      expect(sql).to include("CAST(teachers.name AS TEXT) ILIKE")
    end

    it "uses a parent-id subquery for has_many through filters" do
      column = WulinMaster::Column.new(:courses, TeacherGrid)

      sql = column.apply_filter(Teacher, "Alpha", "equals").to_sql

      expect(sql).to include('"teachers"."id" IN (SELECT DISTINCT "teachers"."id"')
      expect(sql).to include('INNER JOIN "trainings"')
      expect(sql).to include('INNER JOIN "courses"')
      expect(sql).to include("CAST(courses.name AS TEXT) ILIKE")
    end

    it "keeps not_equals on the subquery path" do
      column = WulinMaster::Column.new(:courses, TeacherGrid)

      sql = column.apply_filter(Teacher, "Alpha", "not_equals").to_sql

      expect(sql).to include('"teachers"."id" IN (SELECT DISTINCT "teachers"."id"')
      expect(sql).to include("CAST(courses.name AS TEXT) NOT ILIKE")
    end
  end

  describe "through-association row rendering" do
    it "keeps all associated values after filtering by one associated value" do
      matching_teacher = Teacher.create!(name: "Teacher Match", subject: "Math")
      other_teacher = Teacher.create!(name: "Teacher Other", subject: "Science")

      alpha_client = Client.create!(name: "Alpha Client")
      beta_client = Client.create!(name: "Beta Client")
      gamma_client = Client.create!(name: "Gamma Client")

      alpha_training = Training.create!(name: "Alpha Training", teacher: matching_teacher, client: alpha_client)
      beta_training = Training.create!(name: "Beta Training", teacher: matching_teacher, client: beta_client)
      other_training = Training.create!(name: "Gamma Training", teacher: other_teacher, client: gamma_client)

      Course.create!(name: "Alpha Course", title: "A", training: alpha_training)
      Course.create!(name: "Beta Course", title: "B", training: beta_training)
      Course.create!(name: "Gamma Course", title: "C", training: other_training)

      grid = build_grid(TeacherScreen, TeacherGrid)
      query = grid.apply_filter(Teacher, "courses_name", "Alpha", "equals")
      objects = apply_grid_includes(query, grid).order("teachers.id ASC").to_a
      row = grid.arraify(objects).first

      courses_index = grid.columns.index { |column| column.name == :courses }
      clients_index = grid.columns.index { |column| column.name == :clients }

      expect(objects).to eq([matching_teacher])
      expect(row[courses_index][:courses][:name]).to eq("Alpha Course, Beta Course")
      expect(row[clients_index][:clients][:name]).to eq("Alpha Client, Beta Client")
    end
  end
end
