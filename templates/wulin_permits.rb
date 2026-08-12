# wulin_permits -- users, roles, privileges and per-screen permissions.
#
# This gem assumes a host app that already has an authentication layer. It has
# no generators and no fallbacks: app/grids/user_grid.rb runs `model User` in
# the class body, five of its controllers declare `before_action :require_admin`
# without defining it, and its grids call user.admin?, user.email and
# User.find_by_ids. So the template supplies a minimal version of all of it.
# Replace it with your real user model and auth.

wulin_vendor "wulin_permits", "develop"

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

wulin_method <<~RB
  # wulin_permits needs both of these and defines neither.
  def current_user
    @current_user ||= User.first
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
  generate :model, "User email:string admin:boolean"

  # find_by_ids is not a Rails method -- it comes from Ekohe's remote user
  # service, and three wulin_permits controllers call it.
  file "app/models/user.rb", <<~RB, force: true
    # frozen_string_literal: true

    class User < ApplicationRecord
      def self.find_by_ids(ids)
        where(id: ids)
      end
    end
  RB

  append_to_file "db/seeds.rb", <<~RB
    # current_user is User.first, so the first user has to be an admin or every
    # require_admin screen 403s.
    User.find_or_create_by!(email: "admin@example.com") { |user| user.admin = true }
  RB
end

wulin_db_post do
  rails_command "db:seed"

  # Creates a read/cud Permission row per registered screen, plus one per
  # non-CRUD route. Singular "load_permission" -- the plural form does not exist.
  rails_command "wulin_permits:load_permission"
end

wulin_note "wulin_permits: User, current_user and require_admin are placeholders -- replace them with your real auth"
wulin_note "wulin_permits: its routes are unnamespaced (resources :users, :roles, :permissions) and will collide with host routes of the same name"
wulin_note "wulin_permits: /permissions 500s upstream -- PermissionsController needs `controller_for_screen PermissionScreen`, so it is left out of the menu"
