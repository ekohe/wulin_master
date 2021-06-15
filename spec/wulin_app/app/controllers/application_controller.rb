# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def self.define_menu
    menu do |_c|
      submenu 'Section 1' do
        item PersonScreen, icon: :people, label: 'People'
        item PostScreen, icon: :apps, label: 'Post'
        item TeacherScreen, icon: :school, label: 'Teacher'
        item AddressScreen, icon: :location_on, label: 'Address'
        # item AnotherPersonScreen, icon: :people, label: :horizontal_layout_people
      end
    end
  end
end
