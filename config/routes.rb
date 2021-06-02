Rails.application.routes.draw do
  namespace :wulin_master do
    post "grid_states_manages/create"
    post "grid_states_manages/save"
    post "grid_states_manages/update"
    post "grid_states_manages/destroy"
    post "grid_states_manages/set_current"
    post "grid_states_manages/batch_update"
    put 'grid_states_manages/reset_default'

    resources :grid_states do
      collection do
        post 'copy'
      end
    end

    resources :app_configs, only: [:index]

    get 'fetch_options', :to => WulinMaster::FetchOptionsController.action(:index)
    get 'specify_fetch', :to => WulinMaster::FetchOptionsController.action(:specify_fetch)
    get 'fetch_distinct_options', :to => WulinMaster::FetchOptionsController.action(:fetch_distinct_options)
    post 'include', :to => WulinMaster::InclusionExclusionController.action(:include)
    post 'exclude', :to => WulinMaster::InclusionExclusionController.action(:exclude)
    get 'detail_controller', :to => WulinMaster::MasterDetailController.action(:detail_controller)
    post 'attach_details', :to => WulinMaster::MasterDetailController.action(:attach_details)
    post 'uploads', to: 'uploads#create'
  end
end
