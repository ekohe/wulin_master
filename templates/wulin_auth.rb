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

  # The first admin's sign-in. .env holds it for docker compose -- gitignored, and kept out of the
  # image by .dockerignore -- and the environment `docker compose up` runs in can hand it over
  # instead, since a fresh clone has no .env. Each value comes from the scaffold's own environment,
  # then from what .env already holds, and only a missing password is generated -- never a fixed
  # default, which would be a known password in every app.
  #
  # Single-quoted in .env: compose reads a quoted value literally, where an unquoted one loses
  # everything after a `#` and expands `$`, so the app would not get the password the scaffold seeded.
  #
  # Keyed on the variable rather than left to Thor, which skips only an identical block: an app made
  # by an earlier version of this template, re-applied, would get a second pair.
  unless File.read(".env.example").match?(/^ADMIN_EMAIL=/)
    append_to_file ".env.example", <<~ENV

      # The first admin, created by db:seed. Fill in the password on a fresh checkout.
      ADMIN_EMAIL='admin@example.com'
      ADMIN_PASSWORD=''
    ENV
  end
  dotenv = File.read(".env")
  held = ->(key) { (value = dotenv[/^#{key}=(.*)$/, 1].to_s)[/\A'(.*)'\z/, 1] || value }
  given = ->(key) { ENV[key].to_s }
  email = [given.call("ADMIN_EMAIL").strip, held.call("ADMIN_EMAIL").strip, "admin@example.com"].find { |v| !v.empty? }
  password = [given.call("ADMIN_PASSWORD"), held.call("ADMIN_PASSWORD"), SecureRandom.alphanumeric(20)].find { |v| !v.empty? }
  [email, password].each do |value|
    next unless value.include?("'") || value.match?(/[\r\n]/)

    raise Thor::Error, "ADMIN_EMAIL / ADMIN_PASSWORD cannot contain a single quote or a line break: " \
      ".env writes them single-quoted, so docker compose reads them literally"
  end
  if [held.call("ADMIN_EMAIL"), held.call("ADMIN_PASSWORD")] != [email, password]
    gsub_file ".env", /^ADMIN_(EMAIL|PASSWORD)=.*\n/, "", verbose: false
    append_to_file ".env", "ADMIN_EMAIL='#{email}'\nADMIN_PASSWORD='#{password}'\n", verbose: false
  end
  # The scaffold's own db:seed runs in this process's environment.
  ENV["ADMIN_EMAIL"] = email
  ENV["ADMIN_PASSWORD"] = password

  # The environment first -- compose, or a deploy's secrets -- then the two ADMIN_ lines of .env, so
  # `bin/rails db:seed` on this machine needs nothing exported. Only those two: the rest of .env is
  # the container's. Without the bang: a password wulin_auth's complexity check rejects leaves a
  # message, not a db:prepare that fails and takes the container's boot down with it.
  append_to_file "db/seeds.rb", <<~RB
    dotenv = Rails.root.join(".env").then { |path| path.exist? ? path.read : "" }
    admin_setting = lambda do |key|
      value = ENV[key].to_s
      next value unless value.strip.empty?

      held = dotenv[/^\#{key}=(.*)$/, 1].to_s
      held[/\\A'(.*)'\\z/, 1] || held
    end
    admin_email = admin_setting.call("ADMIN_EMAIL").strip
    admin_password = admin_setting.call("ADMIN_PASSWORD")
    if admin_email.empty? || admin_password.empty?
      puts "No admin seeded: set ADMIN_EMAIL and ADMIN_PASSWORD, in the environment or in .env, then seed again."
    else
      admin = User.find_or_create_by(email: admin_email) do |user|
        user.password = admin_password
        user.admin = true
      end
      if !admin.persisted?
        puts "Admin user \#{admin_email} NOT created: \#{admin.errors.full_messages.to_sentence}"
      elsif admin.previously_new_record?
        puts "Admin user \#{admin_email} created (password: ADMIN_PASSWORD)"
      else
        puts "Admin user \#{admin_email} already exists -- its password was not changed"
      end
    end
  RB
end

wulin_note "wulin_auth: the first admin signs in with ADMIN_EMAIL / ADMIN_PASSWORD -- from .env (gitignored), or from the environment `docker compose up` runs in; db:seed creates that account and leaves an existing one alone"
