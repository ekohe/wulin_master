require 'action_dispatch/routing/mapper'

# Override +resources+ method
# Add +wulin_master_new_form+ and +wulin_master_edit_form+ action
# FIXME : Find a better way to add this two actions
class ActionDispatch::Routing::Mapper
  
  def resources(*resources, &block)
    options = resources.extract_options!

    if apply_common_behavior_for(:resources, resources, options, &block)
      return self
    end

    resource_scope(:resources, Resource.new(resources.pop, options)) do
      yield if block_given?

      collection do
        get  :wulin_master_new_form
        get  :wulin_master_edit_form
        get  :index if parent_resource.actions.include?(:index)
        post :create if parent_resource.actions.include?(:create)
      end

      new do
        get :new
      end if parent_resource.actions.include?(:new)

      member do
        get    :edit if parent_resource.actions.include?(:edit)
        get    :show if parent_resource.actions.include?(:show)
        put    :update if parent_resource.actions.include?(:update)
        delete :destroy if parent_resource.actions.include?(:destroy)
      end
    end

    self
  end
  
end