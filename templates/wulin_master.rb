# wulin_master -- the framework everything else extends, plus the whole asset
# pipeline. master.js is an ES module and master.sass uses the Sass module
# system, so neither can go through Sprockets: esbuild bundles the javascript,
# dart-sass compiles the stylesheet, and Propshaft serves the results out of
# app/assets/builds.

wulin_vendor "wulin_master", "v3-pin"

gem "dartsass-rails"

wulin_js "../../vendor/gems/wulin_master/app/assets/javascripts/master/master.js"
wulin_sass '@use "../../../vendor/gems/wulin_master/app/assets/stylesheets/master"'

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

file "Procfile.dev", <<~PROCFILE
  web: env RUBY_DEBUG_OPEN=true bin/rails server
  js: yarn build --watch
  css: bin/rails dartsass:watch
PROCFILE

wulin_post do
  # All of this waits until after_bundle on purpose. `rails new -j esbuild` runs
  # javascript:install:esbuild after the template body, and that installer
  # rewrites package.json's build script with `npm pkg set` and calls
  # `yarn add`, which fails outright against a package.json declaring
  # workspaces. Writing it here means it lands after the installer, not before.
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
        "build": "esbuild app/javascript/application.js --bundle --sourcemap --format=esm --outdir=app/assets/builds --public-path=/assets --loader:.woff=file --loader:.woff2=file --external:*.css",
        "copy-icons": "node script/copy_material_icons.js"
      },
      "dependencies": {
        "rails-ujs": "^5.2.0"
      }
    }
  JSON

  # The engine ships its own layout; removing the generated one here rather than
  # in the template body keeps jsbundling from warning about a missing layout.
  remove_file "app/views/layouts/application.html.erb"
  remove_file "app/assets/stylesheets/application.css"

  run "yarn install"
  run "yarn run copy-icons"

  # Writes _theme.generated.scss, which master.sass reads $color-theme from, so
  # it has to happen before the first CSS build.
  rails_command "wulin_master:generate_theme_color_css"

  run "yarn build"
  rails_command "dartsass:build"
end
