# The development stack: an image FROM the shared wulin base, compose with postgres, and
# an entrypoint that prepares the database.
#
# Rails' own Dockerfile is left alone (it is a production/Kamal image), hence
# Dockerfile.dev. Its .dockerignore is reused as-is -- it already excludes .git,
# node_modules, app/assets/builds and .env*, and keeps vendor/, which this image needs.

file ".env.example", <<~ENV
  # Copied to .env at scaffold time; .env is gitignored, and compose treats it as
  # optional -- without it the defaults in docker-compose.yml apply.
  POSTGRES_USER=postgres
  POSTGRES_PASSWORD=password
  DB_HOST=db
  DB_PORT=5432
ENV

run "cp .env.example .env"

# Rails' `/.env*` also swallows the template that is meant to be committed, so only the
# exception is needed -- and it has to come after.
append_to_file ".gitignore", <<~GIT

  !/.env.example
GIT

# One file for the container (DB_HOST=db, from compose) and a local machine (no DB_HOST).
# `.presence ||` rather than ENV.fetch: compose passes these through as empty strings, and
# fetch would return "" where the fallback is wanted.
file "config/database.yml", <<~YAML, force: true
  default: &default
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    host: <%= ENV["DB_HOST"].presence || "localhost" %>
    port: <%= ENV["DB_PORT"].presence || 5432 %>
    username: <%= ENV["POSTGRES_USER"].presence || "postgres" %>
    password: <%= ENV["POSTGRES_PASSWORD"].presence || "password" %>

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

# A committed file, not a Dockerfile heredoc: `COPY <<'EOF'` needs BuildKit, and this
# builds on the legacy builder, where it fails with "no source files were specified".
file "bin/docker-entrypoint-dev.sh", <<~SH, force: true
  #!/bin/sh
  set -e

  # The bundle lives in a named volume seeded from the image, so gems are normally
  # already here and this is a no-op. It matters after a Gemfile change.
  bundle check > /dev/null 2>&1 || {
    echo "[entrypoint] Gems out of sync -- running bundle install..."
    bundle install --jobs "$(nproc)"
  }

  echo "[entrypoint] Checking database..."
  if bin/rails db:version > /dev/null 2>&1; then
    echo "[entrypoint] Database exists -- running migrations..."
    bin/rails db:migrate
  else
    echo "[entrypoint] Database missing -- running db:prepare..."
    bin/rails db:prepare
  fi

  exec "$@"
SH
chmod "bin/docker-entrypoint-dev.sh", 0o755

# FROM the shared base that ships in through the wulin_master submodule; see
# vendor/gems/wulin_master/docker/base.Dockerfile for what it is and how to build it.
# No `# syntax=` line here either -- that opts into BuildKit.
file "Dockerfile.dev", <<~DOCKERFILE, force: true
  ARG BASE_IMAGE=wulin-base:local
  FROM ${BASE_IMAGE} AS base

  FROM base AS deps

  # The whole vendor/gems tree, not a list of gemspecs: a path gem's gemspec can require
  # anything from its own tree. App source arrives later, so editing it does not
  # invalidate bundle install.
  COPY Gemfile Gemfile.lock ./
  COPY vendor/gems ./vendor/gems
  RUN bundle install --jobs "$(nproc)" || { \\
        echo "[deps] bundle install failed -- retrying after cache clear..." && \\
        rm -rf /usr/local/bundle/cache/*.gem && \\
        bundle install --jobs "$(nproc)"; \\
      }

  COPY package.json package-lock.json ./
  RUN npm ci || { echo "[deps] npm ci failed -- retrying after cache clear..." && npm cache clean --force && npm ci; }

  FROM deps AS development
  COPY . .

  # Copied out of /rails so the runtime's `.:/rails` bind mount cannot shadow it.
  COPY bin/docker-entrypoint-dev.sh /usr/local/bin/docker-entrypoint-dev.sh
  RUN chmod +x /usr/local/bin/docker-entrypoint-dev.sh
  ENTRYPOINT ["/usr/local/bin/docker-entrypoint-dev.sh"]

  EXPOSE 3000

  # bin/dev, not `rails server`: Procfile.dev's esbuild and dart-sass watchers are what
  # produce the bundles, without which every page raises Propshaft::MissingAssetError.
  CMD ["./bin/dev"]
DOCKERFILE

file "docker-compose.yml", <<~YAML, force: true
  name: #{app_name}

  services:
    db:
      image: postgres:16-alpine
      # A named volume, never a path under the project: that tree gets reset and
      # re-cloned, and a data directory that disappears mid-run corrupts itself.
      volumes:
        - postgres_data:/var/lib/postgresql/data
      environment:
        POSTGRES_USER: ${POSTGRES_USER:-postgres}
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-password}
        POSTGRES_HOST_AUTH_METHOD: trust
        PGDATA: /var/lib/postgresql/data/pgdata
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER:-postgres}"]
        interval: 5s
        timeout: 5s
        retries: 10

    app:
      build:
        context: .
        dockerfile: Dockerfile.dev
        target: development
        args:
          # The tag base.Dockerfile produces, so `docker compose build` works with no
          # registry credentials. Set BASE_IMAGE to use a published base instead.
          BASE_IMAGE: ${BASE_IMAGE:-wulin-base:local}
      volumes:
        - .:/rails
        # Named volumes, not host paths: Docker seeds these from the image, so what was
        # installed at build time is already there. A host bind starts empty, shadows it,
        # and forces a full reinstall on every first boot.
        - bundle_cache:/usr/local/bundle
        - node_modules:/rails/node_modules
      ports:
        # Overridable (PORT=3001 docker compose up) so two apps can run side by side.
        # The container port stays 3000, matching EXPOSE and Procfile.dev.
        - "${PORT:-3000}:3000"
      env_file:
        - path: .env
          required: false
      environment:
        DB_HOST: db
      depends_on:
        db:
          condition: service_healthy
      # Answers on the port rather than merely having a process -- whatever waits on this
      # container waits to make a request. /up is Rails' own route, so it needs no
      # application routes and no database.
      healthcheck:
        test: ["CMD-SHELL", "curl -fsS -o /dev/null http://localhost:3000/up"]
        interval: 10s
        timeout: 5s
        retries: 30
        start_period: 180s

  volumes:
    postgres_data:
    bundle_cache:
    node_modules:
YAML

wulin_note "docker: Rails' own Dockerfile (production/Kamal) needs Node added before it works -- the app was scaffolded --skip-javascript, so that image has no node, and assets:precompile runs `npm run build`. Dockerfile.dev and docker-compose.yml are the development stack and are unaffected"
wulin_note "docker: build the shared base once, then bring the stack up --\n      docker build -f vendor/gems/wulin_master/docker/base.Dockerfile -t wulin-base:local .\n      docker compose up --build"
wulin_note "docker: the entrypoint runs db:prepare on the first boot and db:migrate afterwards, so no database setup step is needed"
wulin_note "docker: the container runs bin/dev, which builds the javascript and CSS on start and watches them -- `rails server` alone would raise Propshaft::MissingAssetError on every page"
