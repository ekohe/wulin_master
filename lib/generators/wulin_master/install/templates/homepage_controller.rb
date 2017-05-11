class HomepageController < WulinMaster::HomeController
  menu do |_c|
    submenu 'Default' do
      item 'Default', url: "#"
      # item DefaultScreen
    end
  end
end
