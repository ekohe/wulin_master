# The development environment every app gets: .env, a database.yml read from it, and the
# development middleware. The container stack itself is templates/docker_stack.rb.

# Written once: components add their own variables to it after this, and re-applying must not
# put the bare file back over them.
unless File.exist?(".env.example")
  file ".env.example", <<~ENV
    # Read by docker compose only -- nothing on the host loads it, and DB_HOST=db resolves only inside
    # the compose network. Copied to .env at scaffold time; .env is gitignored, and compose treats it
    # as optional -- without it the defaults in docker-compose.yml apply.
    POSTGRES_USER=postgres
    POSTGRES_PASSWORD=password
    DB_HOST=db
    DB_PORT=5432
  ENV
end

# Only when there is none: on an app that already exists (`rails app:template`, which is how a
# component selected later is added), .env holds the values somebody filled in, secrets included.
run "cp .env.example .env" unless File.exist?(".env")

# Rails' `/.env*` also swallows the template that is meant to be committed, so only the
# exception is needed -- and it has to come after. Appended once: a re-applied template would
# otherwise add the line again on every run.
unless File.exist?(".gitignore") && File.read(".gitignore").include?("!/.env.example")
  append_to_file ".gitignore", <<~GIT

    !/.env.example
  GIT
end

# database.yml and docker-compose.yml are written when the app is created and are the app's after that:
# a re-apply leaves them as the app has them.
#
# One file for the container and for a local machine. Every connection setting comes from the
# environment and is otherwise left to libpq: on a local machine that is Rails' own default -- the
# socket, as the OS user -- and in the container compose supplies all of them, with or without a
# .env. `.presence` because compose passes an unset variable through as an empty string.
if !@wulin_scaffolded_before || !File.exist?("config/database.yml")
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
end

environment_config = "config/environments/development.rb"

unless wulin_written?(environment_config, "ActionDispatch::DebugLocks")
  inject_into_file environment_config, after: "Rails.application.configure do\n" do
    <<-RB
  # /rails/locks: which thread holds Rails' code-reload lock, for an app that has stopped answering.
  config.middleware.insert_before Rack::Sendfile, ActionDispatch::DebugLocks

    RB
  end
end

# The container stack -- template.rb's @wulin_docker decides whether it is written.
instance_eval(wulin_read("templates/docker_stack.rb"), "templates/docker_stack.rb") if @wulin_docker
