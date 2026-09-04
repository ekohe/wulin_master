# wulin_master -- the framework everything else extends, plus the whole asset
# pipeline. master.js is an ES module and master.sass uses the Sass module
# system, so neither can go through Sprockets: esbuild bundles the javascript,
# dart-sass compiles the stylesheet, and Propshaft serves the results out of
# app/assets/builds.

wulin_vendor "wulin_master"

gem "dartsass-rails"

# The production assets:precompile hook. Guarded because `-j esbuild` already puts this
# line in the Gemfile, and bundler refuses a gem declared twice.
gem "jsbundling-rails" unless File.read("Gemfile").include?("jsbundling-rails")

# Runs Procfile.dev via bin/dev. In the Gemfile rather than jsbundling's runtime
# `gem install foreman`, so the runtime container gets it from bundle install.
gem "foreman", group: :development unless File.read("Gemfile").include?('gem "foreman"')

# Scaffolded with --skip-test there is otherwise no way to run a test at all: no test/
# because the flag removed it, no spec/ without these.
unless File.read("Gemfile").include?("rspec-rails")
  gem_group :development, :test do
    gem "rspec-rails"
    gem "factory_bot_rails"
  end
end

# dartsass-rails only asks for sass-embedded ~> 1.63, so it resolves to the
# newest release. sass-embedded 1.98 raised its floor to macOS 14: on anything
# older the bundled Dart VM exits with "Current Mac OS X version 12.0 is lower
# than minimum supported version 14.0", no application.css is built, and every
# page then raises Propshaft::MissingAssetError. Linux and macOS 14+ are
# unaffected and should not be held back, so only pin where it actually bites.
if RbConfig::CONFIG["host_os"].include?("darwin") && `sw_vers -productVersion`.to_i < 14
  say_status :pin, "sass-embedded < 1.98 (dart-sass needs macOS 14)", :yellow
  gem "sass-embedded", "< 1.98"
  wulin_note "sass-embedded is pinned below 1.98 because this app was generated on macOS #{`sw_vers -productVersion`.to_i}; 1.98 raised dart-sass's floor to macOS 14. Drop the pin when everyone is on 14+"
end

wulin_js "../../vendor/gems/wulin_master/app/assets/javascripts/master/master.js"
wulin_sass '@use "../../../vendor/gems/wulin_master/app/assets/stylesheets/master"'

# grid_states and user_preferences are keyed by user_id, so wulin_master needs a user of its own.
#
# The auth layer first. An auth gem installs its current_user into an ancestor of ApplicationController
# (wulin_auth: `AbstractController::Base.include WulinAuth::AbstractController`), and a method defined
# here sits closer -- so without `super` it wins, and the app authenticates one user while authorizing
# whoever is first in the table. `User.first` is the fallback for an app with no auth gem, where
# wulin_permits generates a `User`. Both guarded: an app with neither has no current user, which the
# gem's controllers answer for rather than raise on.
wulin_method <<~RB
  def current_user
    @current_user ||= if defined?(super)
      super
    elsif defined?(User)
      User.first
    end
  end
RB

wulin_app_config <<~YAML
  wulin_master:
    app_title: "#{app_name.titleize}"
    color_theme: blue
    master_detail_color_theme: blue-grey
    button_mode: merged
    always_reset_form: false
    # app_title_height: 40px
    # default_year: 2026
    # nav_sidebar_partial_path: ""
YAML

file "config/app_config_loader.rb", <<~RB
  # frozen_string_literal: true

  require "active_support/core_ext/hash/indifferent_access"
  require "yaml"

  class AppConfigLoader
    def self.load(config_dir: __dir__)
      path = File.join(config_dir, "app_config.yml")
      return {}.with_indifferent_access unless File.exist?(path)

      (YAML.load_file(path) || {}).with_indifferent_access
    end
  end
RB

# APP_CONFIG has to exist before the gems load: config/initializers/wulin_master.rb
# reads it, and wulin_audit touches it on every write. The rescue keeps a missing
# or malformed app_config.yml from being a boot failure.
inject_into_file "config/application.rb", <<~RB, before: "Bundler.require(*Rails.groups)"
  begin
    require_relative "app_config_loader"
    APP_CONFIG = AppConfigLoader.load
  rescue Exception => e
    APP_CONFIG = {}
    puts e.message
    puts "config/app_config.yml is not configured -- copy config/app_config.example.yml over it."
  end

RB

# material-icons keeps its webfonts inside node_modules and the compiled CSS
# refers to them by bare filename, so they have to be copied where Propshaft
# can index them.
file "script/copy_material_icons.js", <<~JS
  const fs = require("fs");
  const path = require("path");

  const srcDir = path.join(__dirname, "..", "node_modules", "material-icons", "iconfont");
  const dstDir = path.join(__dirname, "..", "app", "assets", "fonts");

  fs.mkdirSync(dstDir, { recursive: true });

  for (const name of [
    "material-icons.woff2",
    "material-icons.woff"
  ]) {
    fs.copyFileSync(path.join(srcDir, name), path.join(dstDir, name));
    console.log(`Copied ${name}`);
  }
JS

empty_directory "app/assets/fonts"

# The esbuild output directory. `-j esbuild` creates it; --skip-javascript does not.
create_file "app/assets/builds/.keep", ""

# A component can drag Sprockets in (wulin_auth declares sass-rails), and Sprockets
# refuses to boot without this file. Unconditional: keying it off a list of component
# gems breaks the first time one of them changes its dependencies.
#
# ../builds and not ../stylesheets -- dart-sass writes application.css into builds, and
# linking both declares two sources for one output (Sprockets::DoubleLinkError).
file "app/assets/config/manifest.js", <<~JS, force: true
  //= link_tree ../images
  //= link_tree ../builds
JS

initializer "wulin_master_assets.rb", <<~RB
  # frozen_string_literal: true

  require "dartsass-rails"

  Rails.application.configure do
    config.assets.paths << Rails.root.join("app/assets/builds")
    config.assets.paths << Rails.root.join("app/assets/fonts")
    config.assets.precompile += %w[*.woff *.woff2]

    # Not a no-op: sassc-rails arrives with Sprockets and sets this to :sass everywhere
    # but development, and libsass cannot re-parse dart-sass output -- SassC::SyntaxError
    # on every page under test and production.
    config.assets.css_compressor = nil

    config.dartsass.builds = {"application.sass" => "application.css"}

    # Three load paths, all of them load-bearing:
    #   node_modules  -- master.sass @use's npm packages by bare name
    #   app/assets/stylesheets -- where generate_theme_color_css writes
    #     _theme.generated.scss, which master.sass reads $color-theme from
    #   the gem's own stylesheets -- its SlickGrid partials @import "base"
    #     and friends relative to that directory
    config.dartsass.build_options << "--load-path=node_modules"
    config.dartsass.build_options << "--load-path=app/assets/stylesheets"
    config.dartsass.build_options << "--load-path=vendor/gems/wulin_master/app/assets/stylesheets"
  end
RB

# Rails' .gitignore lists none of these, and under --skip-javascript nothing else adds
# them -- so without this the first commit carries node_modules.
append_to_file ".gitignore", <<~GIT

  # Node dependencies and the bundled assets, both rebuilt by bin/dev
  /node_modules
  /app/assets/builds/*
  !/app/assets/builds/.keep
GIT

wulin_post do
  # These three files are written here, not in the template body: `-j esbuild` runs
  # javascript:install:esbuild in between and overwrites them.
  esbuild = "esbuild app/javascript/application.js --bundle --sourcemap --format=esm " \
    "--outdir=app/assets/builds --public-path=/assets " \
    "--loader:.woff=file --loader:.woff2=file --external:*.css"

  # --watch=forever, not --watch: foreman closes stdin, plain --watch takes that as the
  # signal to stop, and foreman then SIGTERMs the container seconds after boot.
  file "package.json", <<~JSON, force: true
    {
      "name": "app",
      "private": true,
      "workspaces": [
        "vendor/gems/wulin_master"
      ],
      "devDependencies": {
        "esbuild": "^0.25.9"
      },
      "scripts": {
        "build": "#{esbuild}",
        "build:watch": "#{esbuild} --watch=forever",
        "copy-icons": "node script/copy_material_icons.js"
      },
      "dependencies": {
        "rails-ujs": "^5.2.0"
      }
    }
  JSON

  # -b 0.0.0.0: Rails 7.1+ binds development to localhost, unreachable through a
  # published container port. -p 3000: foreman assigns PORT from 5000 up and `rails
  # server` honours it, so the app would answer on 5000 while compose expects 3000.
  file "Procfile.dev", <<~PROCFILE, force: true
    web: env RUBY_DEBUG_OPEN=true bin/rails server -b 0.0.0.0 -p 3000
    js: npm run build:watch
    css: bin/rails dartsass:watch
  PROCFILE

  # Rails' bin/dev is `exec "./bin/rails", "server", *ARGV` -- it never reads
  # Procfile.dev, so the asset watchers never start.
  file "bin/dev", <<~SH, force: true
    #!/usr/bin/env bash
    exec bundle exec foreman start -f Procfile.dev "$@"
  SH
  chmod "bin/dev", 0o755

  # The engine ships its own layout; removing the generated one here rather than
  # in the template body keeps jsbundling from warning about a missing layout.
  remove_file "app/views/layouts/application.html.erb"
  remove_file "app/assets/stylesheets/application.css"

  # wulin_master:install writes this file with every setting commented out.
  # Replace it with one that reads config/app_config.yml, so a deploy changes
  # YAML rather than Ruby. This has to precede generate_theme_color_css below,
  # which reads config.color_theme.
  file "config/initializers/wulin_master.rb", <<~RB, force: true
    # frozen_string_literal: true

    # Settings live in config/app_config.yml under the wulin_master key. The
    # fallbacks here are what the app runs on if that file is missing.
    wulin = APP_CONFIG.fetch("wulin_master", {})

    WulinMaster.configure do |config|
      config.app_title = wulin["app_title"].presence || "#{app_name.titleize}"

      # Must not be blank: wulin_master:generate_theme_color_css exits 1 if it is.
      config.color_theme = wulin["color_theme"].presence || "blue"
      config.master_detail_color_theme = wulin["master_detail_color_theme"].presence || "blue-grey"

      config.button_mode = wulin["button_mode"].presence || "merged"
      config.always_reset_form = !!wulin["always_reset_form"]

      # A proc so the year is evaluated per request rather than frozen at boot.
      config.default_year = proc { wulin["default_year"].presence || Time.now.year }

      if wulin["app_title_height"].present?
        config.app_title_height = wulin["app_title_height"]
      end

      if wulin["nav_sidebar_partial_path"].present?
        config.nav_sidebar_partial_path = wulin["nav_sidebar_partial_path"]
      end
    end
  RB

  # abort_on_failure on all four: the layout calls stylesheet_link_tag and
  # javascript_include_tag, so an app whose assets did not build raises
  # Propshaft::MissingAssetError on every page. Failing here is far better than
  # printing "components installed" over a broken app.
  #
  # npm, not yarn or pnpm. yarn's shell refuses to exec node_modules binaries on a
  # Docker Desktop bind mount ("permission denied: esbuild", exit 128) and globs unquoted
  # script arguments; yarn 2+ also needs nodeLinker to produce a real node_modules, which
  # copy_material_icons.js and dart-sass's --load-path both read by path, and pnpm's
  # symlinked tree is not it. A yarn.lock left by `-j esbuild` has to go too: jsbundling
  # picks its tool from whichever lockfile it finds first.
  remove_file "yarn.lock" if File.exist?("yarn.lock")
  run "npm install", abort_on_failure: true
  run "npm run copy-icons", abort_on_failure: true

  # Writes _theme.generated.scss, which master.sass reads $color-theme from, so
  # it has to happen before the first CSS build.
  rails_command "wulin_master:generate_theme_color_css", abort_on_failure: true

  run "npm run build", abort_on_failure: true
  rails_command "dartsass:build", abort_on_failure: true

  # Before any other generator: rspec-rails takes over `generate`, so a model generated after this
  # writes a spec that needs the harness to be there already.
  rails_command "generate rspec:install"

  # No `User` model and no user seed here. The `users` table belongs to whichever auth gem the app
  # installs: wulin_auth ships `CreateUsers` on its own migration path, and a second migration class
  # of that name raises DuplicateMigrationNameError while Rails scans, before any migration runs. Its
  # body is `unless table_exists?(:users)` -- the table is meant to be shared, the class name is what
  # collides.
  #
  # An app with no auth gem therefore has no user, and wulin_master works without one: a grid renders,
  # a grid state or a menu pin is not stored. Add a `User` and a `current_user` to get them back.
end
