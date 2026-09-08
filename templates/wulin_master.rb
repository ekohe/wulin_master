# wulin_master -- the framework everything else extends, plus the whole asset
# pipeline. master.js is an ES module and master.sass uses the Sass module
# system, so neither can go through Sprockets: esbuild bundles the javascript,
# dart-sass compiles the stylesheet, and Propshaft serves the results out of
# app/assets/builds.

wulin_vendor "wulin_master", "v3"

gem "bcrypt"
gem "dartsass-rails"

# json 3.0 changed JSON.parse to accept only 1 argument; Rails 8.1's
# ActiveSupport::JSON.decode passes 2. Every request that touches the session
# (including csrf_meta_tags) dies with ArgumentError.
gem "json", "< 3.0"

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

wulin_js "../../vendor/gems/wulin_master/app/assets/javascripts/master/master.esm.js"
wulin_sass '@use "../../../vendor/gems/wulin_master/app/assets/stylesheets/master"'

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
  rescue StandardError => e
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

initializer "wulin_master_assets.rb", <<~RB
  # frozen_string_literal: true

  require "dartsass-rails"

  Rails.application.configure do
    config.assets.paths << Rails.root.join("app/assets/builds")
    config.assets.paths << Rails.root.join("app/assets/fonts")
    config.assets.precompile += %w[*.woff *.woff2]

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

wulin_post do
  # Procfile.dev must be written here, not in the template body. `rails new
  # -j esbuild` appends `js: yarn build --watch` to Procfile.dev after the
  # template body runs, creating a duplicate js entry. Writing with force:
  # true inside wulin_post (which runs in after_bundle) replaces it cleanly.
  file "Procfile.dev", <<~PROCFILE, force: true
    web: env RUBY_DEBUG_OPEN=true bin/rails server
    js: yarn build:watch
    css: bin/rails dartsass:watch
  PROCFILE
  # All of this waits until after_bundle on purpose. `rails new -j esbuild` runs
  # javascript:install:esbuild after the template body, and that installer
  # rewrites package.json's build script with `npm pkg set` and calls
  # `yarn add`, which fails outright against a package.json declaring
  # workspaces. Writing it here means it lands after the installer, not before.
  file "package.json", <<~JSON, force: true
    {
      "name": "#{app_name}",
      "private": true,
      "workspaces": [
        "vendor/gems/wulin_master"
      ],
      "devDependencies": {
        "esbuild": "^0.28.0"
      },
      "dependencies": {
        "rails-ujs": "^5.2.0"
      },
      "scripts": {
        "build": "esbuild app/javascript/application.js --bundle --sourcemap --format=iife --outfile=app/assets/builds/application.js --public-path=/assets --loader:.woff=file --loader:.woff2=file --external:*.css",
        "build:watch": "esbuild app/javascript/application.js --bundle --sourcemap --format=iife --outfile=app/assets/builds/application.js --public-path=/assets --loader:.woff=file --loader:.woff2=file --external:*.css --watch=forever",
        "copy-icons": "node script/copy_material_icons.js"
      }
    }
  JSON

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
  run "yarn install", abort_on_failure: true
  run "yarn run copy-icons", abort_on_failure: true

  # Writes _theme.generated.scss, which master.sass reads $color-theme from, so
  # it has to happen before the first CSS build.
  rails_command "wulin_master:generate_theme_color_css", abort_on_failure: true

  run "yarn build", abort_on_failure: true
  rails_command "dartsass:build", abort_on_failure: true
end
