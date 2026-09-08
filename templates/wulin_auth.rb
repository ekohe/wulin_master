# wulin_auth -- session-based email+password authentication.
#
# Provides login/logout, current_user, require_login, password reset.
# Its User model has has_secure_password, so bcrypt is required.
#
# The login page has its own layout (wulin_auth.html.haml) that loads
# wulin_auth.css and wulin_auth.js independently of the main app assets.
# Both are Sprockets-era manifests, so the template creates Propshaft-
# compatible entry points: a dart-sass source and an esbuild bundle.

wulin_vendor "wulin_auth", "rails8"

# --- login page CSS ---
# wulin_auth's wulin_auth.css.sass imports setting.scss.erb (ERB that
# reads WulinMaster.config.color_theme) and materialize. dart-sass can't
# process ERB, so we write a plain-Sass entry that sets the variable
# directly and @import's the rest from the gem.
file "app/assets/stylesheets/wulin_auth.sass", <<~SASS
  // Login page stylesheet — compiled by dart-sass, served by Propshaft.
  $main-color: blue
  @use 'materialize-css/sass/components/color-variables' as materialize_color
  $primary-color: materialize_color.color($main-color, "lighten-2") !default
  $secondary-color: materialize_color.color($main-color, "base") !default

  @use 'material-icons/iconfont/material-icons'
  @use 'materialize-css/sass/materialize'
  @import 'materialize.overrides'

  html
    height: 100%

  body
    height: 100%
    background: #ECEFF1

  #container
    height: 100%

  .card.larger
    width: 400px

  #password-container
    position: relative

  #password-img
    position: absolute
    bottom: 25px
    right: 5px

  .btn input[type="submit"]
    cursor: pointer
    color: white

  .login-submit
    color: white
SASS

# --- login page JS ---
# wulin_auth.js is a Sprockets manifest (//= require). We create an
# esbuild entry that imports jQuery, materialize, and login.js.
file "app/javascript/wulin_auth.js", <<~JS
  import jQuery from "jquery"
  window.$ = window.jQuery = jQuery
  import "materialize-css"
  import "../../vendor/gems/wulin_auth/app/assets/javascripts/login.js"
JS

wulin_post do
  # Add wulin_auth as a second dart-sass build and load path.
  inject_into_file "config/initializers/wulin_master_assets.rb",
    after: '  config.dartsass.builds = {"application.sass" => "application.css"}' + "\n" do
    <<~RB
      config.dartsass.builds["wulin_auth.sass"] = "wulin_auth.css"
    RB
  end

  inject_into_file "config/initializers/wulin_master_assets.rb",
    after: '--load-path=vendor/gems/wulin_master/app/assets/stylesheets"' + "\n" do
    <<~RB
      config.dartsass.build_options << "--load-path=vendor/gems/wulin_auth/app/assets/stylesheets"
    RB
  end

  # Add wulin_auth.js as a second esbuild entry point. Switch from
  # --outfile (single entry) to --outdir (multiple entries).
  gsub_file "package.json",
    "--outfile=app/assets/builds/application.js",
    "--outdir=app/assets/builds"
  gsub_file "package.json",
    "app/javascript/application.js",
    "app/javascript/application.js app/javascript/wulin_auth.js"

  # wulin_auth's migration lives in the engine. Add the admin column
  # via a separate app-level migration.
  generate :migration, "AddAdminToUsers admin:boolean"

  append_to_file "db/seeds.rb", <<~RB
    admin_password = SecureRandom.alphanumeric(16)
    User.find_or_create_by!(email: "admin@example.com") do |user|
      user.password = admin_password
      user.admin = true
    end
    puts "Admin user: admin@example.com / \#{admin_password}"
  RB
end
