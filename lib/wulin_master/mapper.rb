module WulinMaster
  module FormResourceRoute
    def resources(*args, &block)
      super(*args) do
        yield if block_given?
        collection do
          get :wulin_master_new_form
          get :wulin_master_edit_form
          get :wulin_master_option_new_form
          get :wulin_master_preview
        end
      end
    end
  end
end

ActionDispatch::Routing::Mapper.send(:include, WulinMaster::FormResourceRoute)
