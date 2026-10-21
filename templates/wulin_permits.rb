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

# Users get roles, roles get privileges, privileges get permissions. UserScreen, RoleScreen and the
# legacy MasterUserDetailPrivilegeScreen stay in the gem, off a new app's menu.
#
# Each item opens its screen's own path, and its reverse is the paired screen's path; the join
# routes beside them serve detail-grid data, not pages. MasterPrivilegeRoleScreen's own path,
# /privileges_roles, is not a route, so its reverse opens on /roles. The paths are literals:
# wulin_component_menus is a class method, with no request to call route helpers on.
wulin_menu <<~RB
  submenu "Access Control" do
    item MasterUserDetailRoleScreen, icon: :group_add,
      reverse: "/roles?screen=MasterRoleDetailUserScreen"
    item MasterRolePrivilegeScreen, icon: :vpn_key,
      reverse: "/roles?screen=MasterPrivilegeRoleScreen",
      label: "Roles / Privileges"
    item PrivilegeScreen, icon: :fingerprint,
      reverse: "/permissions?screen=MasterPermissionPrivilegeScreen",
      label: "Privileges / Permissions"
    item MasterUserDetailPermissionScreen, icon: :lock,
      reverse: "/permission_all_users?screen=MasterPermissionDetailUserScreen",
      label: "Permissions / Users"
    item PermissionScreen, icon: :security
  end
RB

wulin_post do
  # Called from the query_initialized callback of roles_users, permission_all_users and
  # users_privileges, so it runs as those grids load. Defined in no gem on this stack.
  unless wulin_written?("app/models/user.rb", "def self.find_by_ids")
    inject_into_class "app/models/user.rb", "User", <<~RB
      def self.find_by_ids(ids)
        where(id: ids)
      end
    RB
  end
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
