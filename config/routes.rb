Rails.application.routes.draw do
  # get '/:controller/wulin_master_edit_form', :controller => /[^\/]+/ 
  
  post "/wulin_master/grid_states/save"
  
  match '/wulin_master/fetch_options', :to => WulinMaster::FetchOptionsController.action(:index)
  
  match '/wulin_master/specify_fetch', :to => WulinMaster::FetchOptionsController.action(:specify_fetch)
end