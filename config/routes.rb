Rails.application.routes.draw do
  namespace :wulin_master do
    post "grid_states_manages/save"
    post "grid_states_manages/update"
    get "grid_states_manages/manage"
    post "grid_states_manages/batch_update"

    resources :grid_states do
      collection do
        post 'copy'
      end
    end

    match 'change_password' => 'home#change_password', via: [:get, :post], as: :change_password
    match 'fetch_options', :to => WulinMaster::FetchOptionsController.action(:index)
    match 'specify_fetch', :to => WulinMaster::FetchOptionsController.action(:specify_fetch)
    post 'include', :to => WulinMaster::InclusionExclusionController.action(:include)
    post 'exclude', :to => WulinMaster::InclusionExclusionController.action(:exclude)
    get 'get_detail_controller', :to => WulinMaster::MasterDetailController.action(:get_detail_controller)
    post 'attach_details', :to => WulinMaster::MasterDetailController.action(:attach_details)
    match 'js_error_report', :to => WulinMaster::ExceptionReportController.action(:js_error)
  end
end