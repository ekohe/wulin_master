# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def self.define_menu
    menu do |_c|
      submenu 'Section 1' do
        item PersonScreen, icon: :people
      end
    end
  end
end
