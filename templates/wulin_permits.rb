# wulin_permits -- users, roles, privileges and per-screen permissions.
#
# This gem assumes a host app that already has an authentication layer. It has
# no generators and no fallbacks: app/grids/user_grid.rb runs `model User` in
# the class body, five of its controllers declare `before_action :require_admin`
# without defining it, and its grids call user.admin?, user.email and
# User.find_by_ids. So the template supplies a minimal version of all of it.
# Replace it with your real user model and auth.

wulin_vendor "wulin_permits"

wulin_js "../../vendor/gems/wulin_permits/app/assets/javascripts/actions/user_role.js",
  "../../vendor/gems/wulin_permits/app/assets/javascripts/actions/export_privilege_permission.js",
  "../../vendor/gems/wulin_permits/app/assets/javascripts/actions/import_privilege_permission.js"

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

# current_user and the User model come from templates/wulin_master.rb, which
# needs them too. This is the part only wulin_permits wants: five of its
# controllers declare before_action :require_admin and none of them define it.
wulin_method <<~RB
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

# The `User` model, because wulin_permits is what needs one -- its grids, controllers and Role#users
# name a top-level `User` no gem in the suite defines. Here rather than for every app, so an app that
# installs an auth gem instead is left the `users` table that gem owns.
#
# `find_by_ids` is not a Rails method -- it comes from Ekohe's remote user service, and three
# wulin_permits controllers call it.
#
# wulin_permits AND an auth gem needs a hand: drop this model, let the gem's migration create the
# table, and wulin_permits' engine falls through to the gem's user class.
#
# In wulin_post, not out here: a component template's body runs while the Gemfile is still being
# assembled, and `generate` needs the bundle. wulin_master's wulin_post runs first and installs the
# RSpec harness this model's generated spec needs.
wulin_post do
  generate :model, "User email:string admin:boolean"

  # current_user is User.first until real auth replaces it, so the first user has to be an admin or
  # every require_admin screen 403s. db:seed runs after every wulin_post block.
  append_to_file "db/seeds.rb", <<~RB
    User.find_or_create_by!(email: "admin@example.com") { |user| user.admin = true }
  RB

  # Indented here because inject_into_class inserts the string verbatim.
  inject_into_class "app/models/user.rb", "User", <<-RB
  def self.find_by_ids(ids)
    where(id: ids)
  end
  RB
end

wulin_db_post do
  # Creates a read/cud Permission row per registered screen, plus one per
  # non-CRUD route. Singular "load_permission" -- the plural form does not exist.
  rails_command "wulin_permits:load_permission"
end

wulin_note "wulin_permits: require_admin is a placeholder -- replace it, and User/current_user, with your real auth"
wulin_note "wulin_permits: its routes are unnamespaced (resources :users, :roles, :permissions) and will collide with host routes of the same name"
wulin_note "wulin_permits: /permissions 500s upstream -- PermissionsController needs `controller_for_screen PermissionScreen`, so it is left out of the menu"
