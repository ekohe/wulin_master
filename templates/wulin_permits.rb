# wulin_permits -- users, roles, privileges and per-screen permissions.
#
# This gem assumes a host app that already has an authentication layer, which is why it needs
# wulin_auth: app/grids/user_grid.rb runs `model User` in the class body and its grids call
# user.admin?, user.email and User.find_by_ids. It has no generators and no fallbacks: wulin_auth
# brings the User model and the columns, and the names the gem calls but defines nowhere are supplied
# below.

wulin_vendor "wulin_permits"

wulin_js "../../vendor/gems/wulin_permits/app/javascript/wulin_permits.esm.js"

# Inlined rather than @use'd: the gem's file is named role_screen.css.scss, and
# dart-sass reads a .css extension as plain CSS rather than Sass.
wulin_sass <<~SASS.strip
  #action_btns
    display: none
    padding: 120px 10px 0
    vertical-align: top
    button
      display: block
      width: 100px
      padding-left: 5px
      padding-right: 5px
      &.danger
        margin-top: 10px
SASS

# The User model comes from wulin_auth, which this component `needs`. This is the part only
# wulin_permits wants: permission_all_users, user_all_permissions and users_privileges each declare
# `before_action :require_admin`, and nothing in the gem defines it. Replace this one with your real
# authorization.
#
# wulin_auth's current_user returns WulinAuth::User.find(...), while the engine includes the
# permission methods into the app's User subclass -- so the object the enforcement callback is handed
# would not carry the methods it calls. Override current_user to return a User instance.
wulin_method <<~RB
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = session[:user_id] ? User.find_by(id: session[:user_id]) : nil
  end

  def require_admin
    head :forbidden unless current_user&.admin?
  end
RB

# PermissionScreen is deliberately not linked: wulin_permits'
# PermissionsController is an empty class with no controller_for_screen, so
# screen_classes is nil and /permissions raises NoMethodError in
# wulin_master's Variables#screen. See the note at the bottom of this file.
wulin_menu <<~RB
  submenu "Settings" do
    item UserScreen, icon: :people
    item RoleScreen, icon: :assignment_ind
    item PrivilegeScreen, icon: :vpn_key
  end
RB

wulin_post do
  # Called from the query_initialized callback of roles_users, permission_all_users and
  # users_privileges, so it runs as those grids load. Defined in no gem on this stack.
  inject_into_class "app/models/user.rb", "User", <<~RB
    def self.find_by_ids(ids)
      where(id: ids)
    end
  RB
end

wulin_db_post do
  # Creates a read/cud Permission row for every screen CLASS the task can load -- it globs
  # vendor/gems/*/app/screens and app/screens and requires them, and WulinMaster::Screen.inherited
  # registers each subclass as it is defined. The menu does not come into it, so a screen left off one
  # still gets its pair. Plus one row per non-CRUD route. Singular "load_permission" -- the plural
  # form does not exist.
  rails_command "wulin_permits:load_permission"
end

wulin_note "wulin_permits: require_admin is a placeholder -- replace it, and User/current_user, with your real auth"
wulin_note "wulin_permits: its routes are unnamespaced (resources :users, :roles, :permissions) and will collide with host routes of the same name"
wulin_note "wulin_permits: /permissions 500s upstream -- PermissionsController needs `controller_for_screen PermissionScreen`, so it is left out of the menu"
