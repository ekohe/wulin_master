# rails new wulin_app --skip-hotwire --database=postgresql -j esbuild -m ./template.rb

run "git submodule add -b v3-pin https://github.com/ekohe/wulin_master.git vendor/gems/wulin_master"
run "git config -f .gitmodules submodule.vendor/gems/wulin_master.branch v3-pin"

gem "wulin_master", path: "vendor/gems/wulin_master"

gem "dartsass-rails"

# Add wulin master javascript to application.js:
file "app/javascript/application.js", <<~JS
  // Import Wulin Master modules
  import '../../vendor/gems/wulin_master/app/assets/javascripts/master/master.js'
JS

# Remove application.css file
remove_file "app/assets/stylesheets/application.css"

# Add wulin master stylesheet to application.sass
file "app/assets/stylesheets/application.sass", <<~CSS
  @use "../../../vendor/gems/wulin_master/app/assets/stylesheets/master";
CSS

# Remove application.html.erb
remove_file "app/views/layouts/application.html.erb"

# Setup package.json
file "package.json", <<~JSON
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

# Create fonts directory
run "mkdir -p app/assets/fonts"

# Add fonts in assets.rb initializer
run "rm config/initializers/assets.rb"

initializer "assets.rb", <<~RB
  # Be sure to restart your server when you modify this file.

  # Version of your assets, change this if you want to expire all your assets.
  Rails.application.config.assets.version = "1.0"

  # Add additional assets to the asset load path.
  # Rails.application.config.assets.paths << Emoji.images_path
  Rails.application.config.assets.paths << Rails.root.join("app/assets/fonts")
RB

# Setup script/copy_material_icons.js
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

# Setup Procfile.dev
file "Procfile.dev", <<~PROCFILE
  web: env RUBY_DEBUG_OPEN=true bin/rails server
  js: yarn build --watch
  css: bin/rails dartsass:watch
PROCFILE

# Setup Wulin Master assets initializer
initializer "wulin_master_assets.rb", <<~RB
  # frozen_string_literal: true

  require 'dartsass-rails'

  # Wulin Master assets configuration for Propshaft
  Rails.application.configure do
    # Add builds directory to asset paths
    config.assets.paths << Rails.root.join("app/assets/builds")
    
    # Add assets to precompile
    config.assets.precompile += %w[
      *.woff
      *.woff2
    ]
    
    Rails.application.config.dartsass.builds = {
      "application.sass"  => "application.css"
    }
    
    # Add node_modules to Sass load path for npm packages
    Rails.application.config.dartsass.build_options << "--load-path=node_modules"
  end
RB

after_bundle do
  rails_command "generate wulin_master:install"

  # Run yarn install
  run "yarn install"

  # Run copy fonts
  run "yarn run copy-icons"

  # Run generate color theme
  run "bundle exec rake wulin_master:generate_theme_color_css"
end
