# frozen_string_literal: true

class CourseScreen < WulinMaster::Screen
  title "Courses"

  path "/courses"

  grid CourseGrid
end
