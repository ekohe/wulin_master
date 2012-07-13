Rails.application.routes.draw do
  namespace :wulin_master do
    post "grid_states/save"
    match 'change_password' => 'home#change_password', via: [:get, :post], as: :change_password
    match 'fetch_options', :to => WulinMaster::FetchOptionsController.action(:index)
    match 'specify_fetch', :to => WulinMaster::FetchOptionsController.action(:specify_fetch)
    post 'include', :to => WulinMaster::InclusionExclusionController.action(:include)
    post 'exclude', :to => WulinMaster::InclusionExclusionController.action(:exclude)
    post 'attach_details', :to => WulinMaster::InclusionExclusionController.action(:attach_details)
  end
end