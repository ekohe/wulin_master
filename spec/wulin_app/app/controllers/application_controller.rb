class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def self.define_menu
    menu do |c|
      submenu 'Section 1' do
        item PersonScreen
      end
    end
  end
end
