# The development stack: an image FROM the shared wulin base, compose with postgres, and
# an entrypoint that prepares the database.
#
# Rails' own Dockerfile is left alone (it is a production/Kamal image), hence
# Dockerfile.dev. Its .dockerignore is reused as-is -- it already excludes .git,
# node_modules, app/assets/builds and .env*, and keeps vendor/, which this image needs.

file ".env.example", <<~ENV
  # Read by docker compose only -- nothing on the host loads it, and DB_HOST=db resolves only inside
  # the compose network. Copied to .env at scaffold time; .env is gitignored, and compose treats it
  # as optional -- without it the defaults in docker-compose.yml apply.
  POSTGRES_USER=postgres
  POSTGRES_PASSWORD=password
  DB_HOST=db
  DB_PORT=5432
ENV

# Only when there is none: on an app that already exists (`rails app:template`, which is how a
# component selected later is added), .env holds the values somebody filled in, secrets included.
run "cp .env.example .env" unless File.exist?(".env")

# Rails' `/.env*` also swallows the template that is meant to be committed, so only the
# exception is needed -- and it has to come after.
append_to_file ".gitignore", <<~GIT

  !/.env.example
GIT

# One file for the container and for a local machine. Every connection setting comes from the
# environment and is otherwise left to libpq: on a local machine that is Rails' own default -- the
# socket, as the OS user -- and in the container compose supplies all of them, with or without a
# .env. `.presence` because compose passes an unset variable through as an empty string.
file "config/database.yml", <<~YAML, force: true
  default: &default
    adapter: postgresql
    encoding: unicode
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
    host: <%= ENV["DB_HOST"].presence %>
    port: <%= ENV["DB_PORT"].presence %>
    username: <%= ENV["POSTGRES_USER"].presence %>
    password: <%= ENV["POSTGRES_PASSWORD"].presence %>

  development:
    <<: *default
    database: #{app_name}_development

  test:
    <<: *default
    database: #{app_name}_test

  # A deploy sets DB_HOST, POSTGRES_USER and POSTGRES_PASSWORD; nothing here names a value for it.
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

  # The deps stage links these, and `.:/rails` hides that copy on every start. They are
  # gitignored, so the mount does not bring them either, and a passing `bundle check` does not
  # mean they are here: the bundle volume can already be warm while this directory is empty.
  # Outside the block above, on every boot, before foreman starts `npm run build:watch`.
  echo "[entrypoint] Linking vendored gems..."
  bundle exec ruby script/link_wulin_gems.rb

  # node_modules is a named volume too, filled from the image only when it is first created, so an
  # image rebuilt after a package-lock.json change leaves the old packages in it. The image stamps
  # the lock it installed; a different lock is reinstalled here, after the links npm resolves
  # workspaces through.
  lock_sum=$(sha256sum package-lock.json | cut -d" " -f1)
  if [ "$(cat node_modules/.lock-sha256 2>/dev/null)" != "$lock_sum" ]; then
    echo "[entrypoint] package-lock.json changed -- running npm ci..."
    npm ci
    echo "$lock_sum" > node_modules/.lock-sha256
  fi

  # db:prepare alone, not a db:version probe choosing between it and db:migrate: on Rails 8.1 the
  # probe succeeds against a database that does not exist yet, so the branch that seeds never ran.
  # db:prepare creates, loads and seeds a missing database and only migrates an existing one.
  echo "[entrypoint] Preparing the database..."
  bin/rails db:prepare

  # The test database as well: rspec connects to it and the step above does not create it, so a
  # fresh app's suite dies on ActiveRecord::NoDatabaseError before it loads one example --
  # maintain_test_schema! reaches for the connection before it can create anything with it.
  # db:prepare rather than db:test:prepare, so the test database is created, migrated AND
  # seeded the way the development one is, and a suite that reads a seeded row finds it.
  # Idempotent, so every boot after the first is a no-op; the `||` keeps a container that
  # serves the app from refusing to start over a test database it could not make.
  echo "[entrypoint] Preparing the test database..."
  RAILS_ENV=test bin/rails db:prepare || echo "[entrypoint] Test database not prepared -- the suite will fail until it is."

  exec "$@"
SH
chmod "bin/docker-entrypoint-dev.sh", 0o755

# The recipe for the base image, copied INTO the app rather than reached through the wulin_master
# gem. An app has to be buildable from its own checkout: a recipe that lives inside a vendored
# dependency is gone the moment the bundle cannot be installed, and a published base image is not
# always reachable.
file "docker/base.Dockerfile", wulin_read("docker/base.Dockerfile"), force: true

# FROM the shared base this app now carries the recipe for; see docker/base.Dockerfile for
# what it is and how to build it.
# No `# syntax=` line here either -- that opts into BuildKit.
file "Dockerfile.dev", <<~DOCKERFILE, force: true
  ARG BASE_IMAGE=wulin-base:local
  FROM ${BASE_IMAGE} AS base

  FROM base AS deps

  # App source arrives later, so editing it does not invalidate bundle install. The wulin
  # components are git gems: bundler clones them here, and nothing of them needs copying in.
  COPY Gemfile Gemfile.lock ./
  RUN bundle install --jobs "$(nproc)" || { \\
        echo "[deps] bundle install failed -- retrying after cache clear..." && \\
        rm -rf /usr/local/bundle/cache/*.gem && \\
        bundle install --jobs "$(nproc)"; \\
      }

  # A git gem's checkout path carries a commit SHA, so it differs between this image and the
  # host the app was scaffolded on. esbuild, dart-sass and the app's own JavaScript all address
  # the components as vendor/gems/<name>; this links that stable path at the real checkout, and
  # it has to run HERE because the SHA is this image's.
  COPY script/link_wulin_gems.rb ./script/
  RUN bundle exec ruby script/link_wulin_gems.rb

  COPY package.json package-lock.json ./
  RUN npm ci || { echo "[deps] npm ci failed -- retrying after cache clear..." && npm cache clean --force && npm ci; }
  # What the entrypoint compares against, so the first boot does not install a second time.
  RUN sha256sum package-lock.json | cut -d" " -f1 > node_modules/.lock-sha256

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

# `config.hosts` is read at boot, and the only way to change it afterwards is to restart the app --
# which, under `bin/dev`, means making foreman's web child exit, which takes the container down with
# it (foreman is PID 1). So the service name the app is reachable by IN the compose network is
# written in now, before the first boot.
#
# Additive: Rails' development default already allows localhost and .localhost.
environment_config = "config/environments/development.rb"
inject_into_file environment_config, after: "Rails.application.configure do\n" do
  <<~RB
    # Reachable by its compose service name from inside the network, not only as localhost.
    # Read at boot: changing it means restarting the app.
    config.hosts << "app" if config.respond_to?(:hosts)

  RB
end

file "docker-compose.yml", <<~YAML, force: true
  name: #{app_name}

  services:
    db:
      image: postgres:16-alpine
      # A named volume, never a path under the project: a checkout is cleaned and re-cloned,
      # and a data directory that disappears mid-run corrupts itself.
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
        # The same credentials the db service is created with, so the app connects whether or not
        # there is a .env -- a fresh clone has none, it is gitignored.
        DB_HOST: db
        POSTGRES_USER: ${POSTGRES_USER:-postgres}
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-password}
        # Every interface, on the container port the mapping above and EXPOSE name. Rails would
        # otherwise bind localhost, unreachable through the mapping, and a PORT in .env would move
        # the server off the port the mapping and the healthcheck point at.
        BINDING: 0.0.0.0
        PORT: "3000"
      # `bin/dev` runs foreman as PID 1, and foreman answers ANY child exiting by shutting the rest
      # down -- so one watcher crashing, or anything that makes the web process exit, ends the
      # container with status 0, and nothing inside can restart it: a `touch tmp/restart.txt` that
      # takes the web process down takes the container with it. `unless-stopped` rather than `on-failure`
      # because that exit IS a zero. An app that cannot boot will loop here, which the healthcheck
      # below reports and is the louder failure of the two.
      restart: unless-stopped
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

# Rails' own Dockerfile is the production image, written for an app without JavaScript (this one is
# made --skip-javascript): its build stage has no Node, and nothing in it links vendor/gems, so
# assets:precompile -- which runs `npm run build` -- cannot work. Both go into the build stage only;
# the final stage copies the built assets and the links, not Node. The links resolve there because
# that stage copies BUNDLE_PATH too.
#
# The lines are anchors Rails owns, so one that moves fails the scaffold here rather than leaving
# an image that cannot build. The Ruby stays the Dockerfile's own: building gems FROM the wulin base
# would compile them for its Ruby and copy them into an image running another.
if File.exist?("Dockerfile")
  [
    [:before, /^# Install application gems\n/, <<~DOCKERFILE],
      # Node for the asset build only: the final stage below copies what it built, not Node.
      ARG NODE_MAJOR=22
      RUN apt-get update -qq && \\
          apt-get install --no-install-recommends -y gnupg && \\
          mkdir -p /etc/apt/keyrings && \\
          curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \\
          echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \\
          apt-get update -qq && \\
          apt-get install --no-install-recommends -y nodejs && \\
          rm -rf /var/lib/apt/lists /var/cache/apt/archives

    DOCKERFILE
    [:before, /^# Precompiling assets for production/, <<~DOCKERFILE],
      # The components are reached as vendor/gems, linked here because a git gem's path carries
      # this image's checkout; npm resolves their workspaces through the links.
      RUN bundle exec ruby script/link_wulin_gems.rb && npm ci

    DOCKERFILE
    # Rails writes this line itself only for an app it set up with a JavaScript bundler. The assets
    # are in public/assets now, and the final stage copies /rails whole.
    [:after, /^RUN SECRET_KEY_BASE_DUMMY=1 \.\/bin\/rails assets:precompile\n/, "\nRUN rm -rf node_modules\n"]
  ].each do |position, anchor, lines|
    unless File.read("Dockerfile").match?(anchor)
      raise Thor::Error, "Dockerfile has no line matching #{anchor.inspect} -- Rails has changed it, " \
        "and the production image would not build its assets"
    end
    inject_into_file "Dockerfile", lines, position => anchor
  end
end
wulin_note "docker: build the shared base once, then bring the stack up --\n      docker build -f docker/base.Dockerfile -t wulin-base:local .\n      docker compose up --build"
wulin_note "docker: the entrypoint runs db:prepare on every boot -- it creates and seeds the database the first time and only migrates it after, so no database setup step is needed"
wulin_note "docker: the container runs bin/dev, which builds the javascript and CSS on start and watches them -- `rails server` alone would raise Propshaft::MissingAssetError on every page"
