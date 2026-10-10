# wulin_auth -- session-based email+password authentication.
#
# Provides login/logout, current_user, require_login, password reset.
# Its User model has has_secure_password, so bcrypt is required.
#
# The login page has its own layout (wulin_auth.html.haml) that loads
# wulin_auth.css and wulin_auth.js independently of the main app assets.
# The stylesheet is a Sprockets-era manifest, so the template creates
# Propshaft-compatible entry points: a dart-sass source and an esbuild bundle.

wulin_vendor "wulin_auth"

# Nothing in the app answers without a session. The filter that says so is declared here rather
# than by wulin_master, because require_login is defined in this gem and the login page it
# redirects to is this gem's.
wulin_filter "before_action :require_login"

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
# The gem's ESM entry needs jQuery and materialize as globals. We create an
# esbuild entry that supplies them and imports it.
file "app/javascript/wulin_auth.js", <<~JS
  import jQuery from "jquery"
  window.$ = window.jQuery = jQuery
  import "materialize-css"
  import "../../vendor/gems/wulin_auth/app/javascript/wulin_auth.esm.js"
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

  # The engine defines WulinAuth::User; the app's own User is the subclass everything else
  # names. It is written here because the seed below creates one and the login page signs it in.
  file "app/models/user.rb", <<~RB
    class User < WulinAuth::User
      self.table_name = "users"
    end
  RB

  # wulin_auth's migration lives in the engine. Add the admin column
  # via a separate app-level migration.
  generate :migration, "AddAdminToUsers admin:boolean"

  # The first account, from the design that asked for this app rather than from this run.
  #
  # A password minted here is different every time the seed runs, lives only in the line that printed
  # it, and is not the one whoever ordered the app is already holding — so the app ships unopenable by
  # the person it was built for. `docs/platform.yaml` carries the account when a designer wrote one;
  # `email` is the word this gem signs people in with, which is why this file is the one that reads it.
  append_to_file "db/seeds.rb", <<~RB
    first_account = begin
      design = YAML.load_file(Rails.root.join("docs/platform.yaml")) || {}
      Array(design["capabilities"]).filter_map { |capability| capability["first_account"] }.first
    rescue Errno::ENOENT, Psych::SyntaxError
      nil
    end

    if first_account
      User.find_or_create_by!(email: first_account.fetch("email")) do |user|
        user.password = first_account.fetch("password")
        user.admin = true
      end
      puts "Admin user: \#{first_account.fetch("email")} -- password in docs/platform.yaml"
    else
      puts "No first account in docs/platform.yaml. Create one: " \\
           "User.create!(email: ..., password: ..., admin: true)"
    end
  RB
end

wulin_note "wulin_auth: db/seeds.rb creates the first admin from docs/platform.yaml (capabilities[].first_account) and leaves an existing one alone; with no such file it creates nobody and prints what to run"

# Seeding nobody is idempotent, so a document that yields no account leaves every probe green and
# ships an app its owner cannot open. Read here only to decide whether to warn -- the seed reads the
# values itself, at seed time, so no part of the credential passes through the scaffold.
if File.exist?("docs/platform.yaml")
  designed = begin
    Array((YAML.load_file("docs/platform.yaml") || {})["capabilities"]).any? { |c| c["first_account"] }
  rescue Psych::SyntaxError
    false
  end
  unless designed
    wulin_note "wulin_auth: docs/platform.yaml is here but names no capabilities[].first_account, so " \
               "db/seeds.rb will create NO admin and nothing behind the login is reachable. Either no " \
               "sign-in capability was selected, or that document's shape moved."
  end
end
