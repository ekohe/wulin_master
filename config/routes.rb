Rails.application.routes.draw do
  namespace :wulin_master do
    post "grid_states/save"
    match 'change_password' => 'home#change_password', via: [:get, :post], as: :change_password
    match 'fetch_options', :to => WulinMaster::FetchOptionsController.action(:index)
    match 'specify_fetch', :to => WulinMaster::FetchOptionsController.action(:specify_fetch)
  end
end