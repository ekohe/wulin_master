# wulin_master -- the framework everything else extends, plus the whole asset
# pipeline. master.js is an ES module and master.sass uses the Sass module
# system, so neither can go through Sprockets: esbuild bundles the javascript,
# dart-sass compiles the stylesheet, and Propshaft serves the results out of
# app/assets/builds.

wulin_vendor "wulin_master"

gem "bcrypt"
gem "dartsass-rails"

# json 3.0 changed JSON.parse to accept only 1 argument; Rails 8.1's
# ActiveSupport::JSON.decode passes 2. Every request that touches the session
# (including csrf_meta_tags) dies with ArgumentError.
gem "json", "< 3.0"

# The production assets:precompile hook. jsbundling-rails' own installer
# (`javascript:install:esbuild`) is never invoked here -- the app is scaffolded
# --skip-javascript and this template drives esbuild itself -- so only the gem
# and the rake task it hooks are needed.
gem "jsbundling-rails" unless File.read("Gemfile").include?("jsbundling-rails")

# Runs Procfile.dev via bin/dev. In the Gemfile rather than jsbundling's runtime
# `gem install foreman`, so the runtime container gets it from bundle install.
gem "foreman", group: :development unless File.read("Gemfile").include?('gem "foreman"')

# Scaffolded with --skip-test there is otherwise no way to run a test at all: no test/ because the
# flag removed it, no spec/ without these.
#
# These two and no more. A matcher library (shoulda-matchers, rspec-collection_matchers) is a
# choice about how to write a spec, and an app makes it for itself -- nothing here needs one.
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

wulin_js "../../vendor/gems/wulin_master/app/javascript/wulin_master.esm.js"
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

# The esbuild output directory. `-j esbuild` creates it; --skip-javascript does not.
create_file "app/assets/builds/.keep", ""

# A component can drag Sprockets in (wulin_auth declares sass-rails), and Sprockets
# refuses to boot without this file. Unconditional: keying it off a list of component
# gems breaks the first time one of them changes its dependencies.
#
# The two dropzone links are this gem's own assets, named because the application layout calls
# `asset_path` on them (app/views/layouts/application.html.haml) and Sprockets serves nothing it was
# not told to. Without them EVERY page through that layout raises AssetNotPrecompiledError -- the app
# boots and `/up` answers 200, so the healthcheck passes and only a request for a real page shows it.
#
# ../builds and not ../stylesheets -- dart-sass writes application.css into builds, and
# linking both declares two sources for one output (Sprockets::DoubleLinkError).
file "app/assets/config/manifest.js", <<~JS, force: true
  //= link_tree ../images
  //= link_tree ../builds
  //= link dropzone.min.js
  //= link dropzone.min.css
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

  # Before any other generator: rspec-rails takes over `generate`, so a model generated
  # by a later component (wulin_auth's admin-column migration, for one) writes a spec
  # that needs the harness to be there already.
  rails_command "generate rspec:install"

  # The two things `rspec:install` leaves undone. `factory_bot_rails` does not include its syntax
  # methods just by being in the Gemfile, and the generated rails_helper ships its support-file
  # loader commented out -- so `create(:thing)` raises NoMethodError in an app whose `spec/` looks
  # complete, which is what makes it expensive to meet rather than merely wrong.
  #
  # They are here because whoever installs a gem owes it working: this template is what puts
  # `factory_bot_rails` in the Gemfile and runs `rspec:install`, so the wiring between them is its
  # own unfinished work, not the first spec author's problem to discover.
  #
  # The loader is APPENDED rather than uncommented because there is no stable line to uncomment:
  # rspec-rails has already moved it once, from `Dir[Rails.root.join('spec', 'support', ...)]` to
  # `Rails.root.glob('spec/support/**/*.rb')`, and `uncomment_lines` against a pattern that stops
  # matching does nothing and says nothing. Appending needs no pattern. Support files call
  # `RSpec.configure` themselves, which merges, so the end of the file is early enough.
  append_to_file "spec/rails_helper.rb", <<~RB

    # rspec:install ships the equivalent line commented out; without it nothing in spec/support is
    # loaded and every `create(:thing)` raises NoMethodError.
    Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }
  RB

  file "spec/support/factory_bot.rb", <<~RB
    # frozen_string_literal: true

    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
  RB

  # npm, not yarn or pnpm. yarn's shell refuses to exec node_modules binaries on a
  # Docker Desktop bind mount ("permission denied: esbuild", exit 128) and globs unquoted
  # script arguments; yarn 2+ also needs nodeLinker to produce a real node_modules, which
  # copy_material_icons.js and dart-sass's --load-path both read by path, and pnpm's
  # symlinked tree is not it. jsbundling-rails' assets:precompile task also picks its
  # tool from whichever lockfile it finds first, so a stray yarn.lock has to go too.
  #
  # install + copy-icons + theme CSS generation happen here so they're ready before any
  # other wulin_post block runs. The final npm build and dartsass:build run in
  # template.rb AFTER all wulin_post blocks, so every component's esbuild/dartsass
  # config changes are in place.
  remove_file "yarn.lock" if File.exist?("yarn.lock")
  run "npm install", abort_on_failure: true
  run "npm run copy-icons", abort_on_failure: true

  # Writes _theme.generated.scss, which master.sass reads $color-theme from, so
  # it has to happen before the first CSS build.
  rails_command "wulin_master:generate_theme_color_css", abort_on_failure: true
end
