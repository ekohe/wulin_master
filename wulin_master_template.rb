# frozen_string_literal: true

# Usage:
#   rails new wulin_app --skip-hotwire --database=postgresql -j esbuild \
#     -m ./wulin_master_template.rb

ruby_ver = begin
  File.read(".ruby-version").strip.sub(/^ruby-/, "")
rescue
  RUBY_VERSION
end

# =============================================================================
# 1. Yarn — use node-modules linker (required for esbuild + workspaces)
# =============================================================================

file ".yarnrc.yml", <<~YAML
  nodeLinker: node-modules
YAML

# =============================================================================
# 2. Wulin Master — add as git submodule
# =============================================================================

run "git submodule add -b v3 https://github.com/Jinxiaoming/wulin_master.git vendor/gems/wulin_master"
run "git config -f .gitmodules submodule.vendor/gems/wulin_master.branch v3"


# =============================================================================
# 3. Gem Dependencies
# =============================================================================

gem "wulin_master", path: "vendor/gems/wulin_master"
gem "dartsass-rails"

# =============================================================================
# 4. JavaScript & CSS
# =============================================================================

file "app/javascript/application.js", <<~JS
  import '../../vendor/gems/wulin_master/app/assets/javascripts/master/master.js'
JS

remove_file "app/assets/stylesheets/application.css"

file "app/assets/stylesheets/application.sass", <<~SASS
  @use "../../../vendor/gems/wulin_master/app/assets/stylesheets/master"
SASS

remove_file "app/views/layouts/application.html.erb"

# =============================================================================
# 5. Package.json — use yarn workspaces to share gem's JS dependencies
# =============================================================================

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
      "build": "esbuild app/javascript/application.js --bundle --sourcemap --outdir=app/assets/builds --public-path=/assets --loader:.woff=file --loader:.woff2=file '--external:*.css'",
      "copy-icons": "node script/copy_material_icons.js"
    },
    "dependencies": {
      "rails-ujs": "^5.2.8"
    }
  }
JSON

# =============================================================================
# 6. Fonts & Asset Pipeline
# =============================================================================

run "mkdir -p app/assets/fonts"
run "rm -f config/initializers/assets.rb"

initializer "assets.rb", <<~RB
  Rails.application.config.assets.version = "1.0"
  Rails.application.config.assets.paths << Rails.root.join("app/assets/fonts")
RB

file "script/copy_material_icons.js", <<~JS
  const fs = require("fs");
  const path = require("path");

  const srcDir = path.join(__dirname, "..", "node_modules", "material-icons", "iconfont");
  const dstDir = path.join(__dirname, "..", "app", "assets", "fonts");

  fs.mkdirSync(dstDir, { recursive: true });

  for (const name of [
    "material-icons.woff2",
    "material-icons.woff",
    "material-icons-outlined.woff2",
    "material-icons-outlined.woff",
    "material-icons-round.woff2",
    "material-icons-round.woff",
    "material-icons-sharp.woff2",
    "material-icons-sharp.woff",
    "material-icons-two-tone.woff2",
    "material-icons-two-tone.woff"
  ]) {
    fs.copyFileSync(path.join(srcDir, name), path.join(dstDir, name));
    console.log("Copied " + name);
  }
JS

# =============================================================================
# 7. Procfile & Dartsass Configuration
# =============================================================================

file "Procfile.dev", <<~PROCFILE, force: true
  web: bin/rails server -b 0.0.0.0
  js: yarn build:watch
  css: bin/rails dartsass:watch
PROCFILE

initializer "wulin_master_assets.rb", <<~RB
  # frozen_string_literal: true

  require 'dartsass-rails'

  Rails.application.configure do
    config.assets.paths << Rails.root.join("app/assets/builds")
    config.assets.precompile += %w[*.woff *.woff2]

    config.dartsass.builds = { "application.sass" => "application.css" }
    config.dartsass.build_options << "--load-path=node_modules"
    config.dartsass.build_options << "--load-path=app/assets/stylesheets"
    config.dartsass.build_options << "--quiet-deps"
    config.dartsass.build_options << "--silence-deprecation=import,global-builtin,slash-div,color-functions"
  end
RB

# =============================================================================
# 8. Docker Support
# =============================================================================

file ".env.example", <<~ENV
  POSTGRES_USER=postgres
  POSTGRES_PASSWORD=password
  DB_HOST=db
  DB_PORT=5432
ENV

run "cp .env.example .env"

append_to_file ".gitignore", <<~GIT

  # Docker
  volumes/
  /.env
  !/.env.example
GIT

file "config/database.yml", <<~YAML, force: true
  default: &default
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    host: <%= ENV.fetch("DB_HOST") { "localhost" } %>
    port: <%= ENV.fetch("DB_PORT") { 5432 } %>
    username: <%= ENV.fetch("POSTGRES_USER") { "postgres" } %>
    password: <%= ENV.fetch("POSTGRES_PASSWORD") { "password" } %>

  development:
    <<: *default
    database: #{app_name}_development

  test:
    <<: *default
    database: #{app_name}_test

  production:
    <<: *default
    database: #{app_name}_production
YAML

file ".dockerignore", <<~TEXT, force: true
  .git
  .env
  node_modules
  volumes
  tmp
  log
  public/assets
TEXT

file "Dockerfile", <<~DOCKERFILE, force: true
  # syntax=docker/dockerfile:1
  ARG RUBY_VERSION=#{ruby_ver}
  ARG NODE_MAJOR=20

  FROM ruby:${RUBY_VERSION}-slim AS base
  WORKDIR /rails

  ARG NODE_MAJOR
  RUN apt-get update -qq && \\
      apt-get install --no-install-recommends -y \\
        build-essential git libpq-dev curl gnupg2 procps \\
        libyaml-dev libvips pkg-config && \\
      mkdir -p /etc/apt/keyrings && \\
      curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \\
      echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \\
      apt-get update -qq && \\
      apt-get install -y --no-install-recommends nodejs && \\
      npm install -g corepack && \\
      corepack enable && \\
      rm -rf /var/lib/apt/lists/*

  FROM base AS deps
  COPY Gemfile Gemfile.lock ./
  COPY vendor/gems/wulin_master ./vendor/gems/wulin_master
  RUN bundle install --jobs 4 || { \\
        echo "[deps] bundle install failed — retrying after cache clear..." && \\
        rm -rf /usr/local/bundle/cache/*.gem && \\
        bundle install --jobs 4; \\
      }

  COPY package.json yarn.lock .yarnrc.yml ./
  RUN yarn install || true

  FROM deps AS development
  COPY . .

  COPY <<'ENTRYPOINT' /usr/local/bin/docker-entrypoint-dev.sh
  #!/bin/sh
  set -e
  bundle check > /dev/null 2>&1 || {
    echo "[entrypoint] Gems out of sync — running bundle install..."
    bundle install --jobs 4
  }
  exec "$@"
  ENTRYPOINT
  RUN chmod +x /usr/local/bin/docker-entrypoint-dev.sh
  ENTRYPOINT ["/usr/local/bin/docker-entrypoint-dev.sh"]

  EXPOSE 3000
  CMD ["./bin/dev"]
DOCKERFILE

run "mkdir -p volumes"

file "docker-compose.yml", <<~YAML
  services:
    db:
      image: postgres:16-alpine
      volumes:
        - ./volumes/postgres_data:/var/lib/postgresql/data
      environment:
        POSTGRES_USER: \${POSTGRES_USER:-postgres}
        POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-password}
        POSTGRES_HOST_AUTH_METHOD: trust
        PGDATA: /var/lib/postgresql/data/pgdata
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U \$\$POSTGRES_USER"]
        interval: 5s
        timeout: 5s
        retries: 5

    app:
      build:
        context: .
        target: development
      volumes:
        - .:/rails
        - ./volumes/bundle_cache:/usr/local/bundle
        - node_modules:/rails/node_modules
      ports:
        - "3000:3000"
      env_file:
        - path: .env
          required: false
      environment:
        DB_HOST: db
      depends_on:
        db:
          condition: service_healthy
      healthcheck:
        test: ["CMD-SHELL", "bundle check > /dev/null 2>&1"]
        interval: 10s
        timeout: 5s
        retries: 30
        start_period: 120s

  volumes:
    node_modules:
YAML

# =============================================================================
# 9. After Bundle
# =============================================================================

after_bundle do
  run "corepack enable"
  run "yarn install"

  rails_command "generate wulin_master:install"

  # jsbundling-rails install overwrites our package.json scripts with
  # --format=esm (breaks jQuery/SlickGrid globals) and drops our custom
  # flags.  Rewrite the build scripts with the correct esbuild invocation.
  esbuild_flags = %w[
    app/javascript/application.js
    --bundle
    --sourcemap
    --outdir=app/assets/builds
    --public-path=/assets
    --loader:.woff=file
    --loader:.woff2=file
    '--external:*.css'
  ].join(" ")

  package_json = JSON.parse(File.read("package.json"))
  package_json["scripts"]["build"]       = "esbuild #{esbuild_flags}"
  package_json["scripts"]["build:watch"]  = "esbuild #{esbuild_flags} --watch=forever"
  File.write("package.json", JSON.pretty_generate(package_json))

  # jsbundling-rails appends a duplicate "js:" line to Procfile.dev; remove it.
  procfile = File.read("Procfile.dev")
  cleaned  = procfile.lines.reject { |l| l.strip == "js: yarn build --watch" }.join
  File.write("Procfile.dev", cleaned)

  run "yarn run copy-icons"
  run "yarn build"
  run "bundle exec rake wulin_master:generate_theme_color_css"
  rails_command "dartsass:build"

  remove_file "app/assets/stylesheets/application.css"

  say ""
  say "=================================================================", :green
  say "  Wulin Master application created successfully!", :green
  say "=================================================================", :green
  say ""
  say "  Docker:  docker compose up --build", :yellow
  say "           docker compose exec app bin/rails db:prepare", :yellow
  say ""
  say "  Local:   bundle install && yarn install", :yellow
  say "           bin/rails db:prepare", :yellow
  say "           bin/dev", :yellow
  say "=================================================================", :green
end
