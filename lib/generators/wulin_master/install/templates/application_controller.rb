# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def self.define_menu
    menu do |_c|
      submenu 'Default' do
        item 'Default', url: "#"
        # item DefaultScreen
      end
    end
  end
end
