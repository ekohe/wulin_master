# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def self.define_menu
    menu do |_c|
      submenu 'Section 1' do
        item PersonScreen
        item PersonScreen, label: 'Normal URL', url: '/example'
        item PersonScreen, label: 'React URL', url: '/example/#/'
      end
    end
  end
end
