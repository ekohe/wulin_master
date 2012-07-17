class HomepageController < WulinMaster::HomeController
  menu do |c|
    submenu 'Default' do
      item 'Default', url: "#"
      # item DefaultScreen
    end
  end
end