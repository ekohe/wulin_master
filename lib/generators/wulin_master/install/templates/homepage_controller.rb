class HomepageController < WulinMaster::HomeController
  
  def self.set_menu
    menu do
      submenu 'Default' do
      end
    end
  end
  
end