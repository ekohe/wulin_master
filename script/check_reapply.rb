#!/usr/bin/env ruby
# frozen_string_literal: true

# Can a component be added to an app that already exists, and does running the template again
# change nothing?
#
#   ruby script/check_reapply.rb
#
# Scaffolds an app with wulin_master alone, in a directory not named after it, and gives it two things
# an app made by an earlier template has: the admin seed that template wrote, unmarked, and React 18
# installed but not declared, as npm left it when wulin_agent still brought React itself. And three an
# app's own development adds: a menu group, a JavaScript import and a style. Then re-applies the
# template for every component, as a component chosen later arrives, and checks that the first admin
# is the one ADMIN_EMAIL / ADMIN_PASSWORD name rather than the one that older seed creates, that the
# app is still on its one React 18 and keeps its databases, and that what it wrote is still there
# beside the components' wiring. Last, re-applies once more and requires a clean tree: a component
# template that appends, injects or overwrites without checking what is already there fails there.
#
# Needs what a scaffold needs: rails, node with npm, a PostgreSQL the default database.yml reaches
# (PGHOST / PGUSER), and network for the pinned components. Exit status is the whole interface.

require "json"
require "tmpdir"

TEMPLATE = File.expand_path("../template.rb", __dir__)
NEW_FLAGS = %w[--skip-hotwire --skip-solid --database=postgresql --skip-javascript --skip-ci --skip-test].freeze
GIT_ENV = {
  "GIT_AUTHOR_NAME" => "check", "GIT_AUTHOR_EMAIL" => "check@example.com",
  "GIT_COMMITTER_NAME" => "check", "GIT_COMMITTER_EMAIL" => "check@example.com"
}.freeze
ADMIN = {"ADMIN_EMAIL" => "admin@example.com", "ADMIN_PASSWORD" => "Tangerine-Harbor-Lantern-58"}.freeze
# What the template appended before its seed had a marked block of its own.
LEGACY_SEED = <<~RB
  admin_password = SecureRandom.alphanumeric(16)
  User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = admin_password
    user.admin = true
  end
  puts "Admin user: admin@example.com / \#{admin_password}"
RB

def step(name, env, *command, chdir:)
  puts "== #{name}"
  output = IO.popen(GIT_ENV.merge(env), command, chdir: chdir, err: [:child, :out], &:read)
  return output if $?.success?

  puts output.lines.last(40).join
  abort "FAIL: #{name}"
end

def check(name)
  abort "FAIL: #{name}" unless yield
  puts "ok: #{name}"
end

# Every version of a package anywhere in an `npm ls --all --json` tree, workspaces included.
def versions(tree, name)
  (tree["dependencies"] || {}).flat_map { |dep, node| (dep == name) ? [node["version"], *versions(node, name)] : versions(node, name) }
end

def commit(app, message)
  system(GIT_ENV, "git", "add", "-A", chdir: app, exception: true)
  system(GIT_ENV, "git", "commit", "-qm", message, chdir: app, exception: true)
end

def edit(app, path)
  file = File.join(app, path)
  File.write(file, yield(File.exist?(file) ? File.read(file) : ""))
end

def read(app, path) = File.read(File.join(app, path))

Dir.mktmpdir("wulin_reapply") do |root|
  # A directory named otherwise, as a container mounts every app at /workspace: the name a re-apply
  # must keep is the app's, which its databases are named after.
  name = "reapply_#{Process.pid}"
  app = File.join(root, "workspace")
  seeds = File.join(app, "db/seeds.rb")
  begin
    step "scaffold with wulin_master alone", {"WULIN_COMPONENTS" => ""},
      "rails", "new", "workspace", "--name=#{name}", "--quiet", *NEW_FLAGS, "-m", TEMPLATE, chdir: root
    File.write(seeds, "#{File.read(seeds)}\n#{LEGACY_SEED}")
    edit(app, "app/controllers/application_controller.rb") do |text|
      text.sub(/^( *)wulin_component_menus\n/) { "#{$1}submenu \"Directory\" do\n#{$1}  item \"Home\", url: \"/\"\n#{$1}end\n#{$&}" }
    end
    edit(app, "app/javascript/own.js") { "window.appOwnScript = true\n" }
    edit(app, "app/javascript/application.js") { |text| "#{text}import \"./own\"\n" }
    edit(app, "app/assets/stylesheets/application.sass") { |text| "#{text}\n.app-own-style\n  color: red\n" }
    step "install React 18", {}, "npm", "install", "--silent", "react@18.3.1", "react-dom@18.3.1", chdir: app
    manifest = File.join(app, "package.json")
    package = JSON.parse(File.read(manifest))
    package["dependencies"] = package["dependencies"].except("react", "react-dom")
    File.write(manifest, "#{JSON.pretty_generate(package)}\n")
    commit app, "scaffold, with an earlier template's admin seed and an undeclared React 18"
    title = read(app, "AGENTS.md").lines.first

    output = step "re-apply for every component", ADMIN.merge("WULIN_COMPONENTS" => "all"),
      "bin/rails", "app:template", "LOCATION=#{TEMPLATE}", chdir: app
    text = File.read(seeds)
    check("the template's admin seed runs ahead of the earlier one") do
      ours, earlier = text.index("# wulin:begin wulin_auth/first_admin"), text.index("admin_password = SecureRandom")
      ours && earlier && ours < earlier
    end
    check("the earlier seed is reported") { output.include?("had code of its own and no wulin_auth/first_admin block") }
    check("the app keeps the React it had, declared, and holds one copy of it") do
      declared = JSON.parse(File.read(manifest))["dependencies"].values_at("react", "react-dom")
      tree = JSON.parse(IO.popen(%w[npm ls react --all --json], chdir: app, &:read))
      declared == %w[^18.3.1 ^18.3.1] && versions(tree, "react").uniq == %w[18.3.1]
    end
    step "the first admin signs in with ADMIN_PASSWORD", ADMIN, "bin/rails", "runner",
      'exit(User.find_by(email: ENV["ADMIN_EMAIL"])&.authenticate(ENV["ADMIN_PASSWORD"]) ? 0 : 1)', chdir: app
    step "no pending migrations", {}, "bin/rails", "runner",
      "exit(ActiveRecord::MigrationContext.new(ActiveRecord::Tasks::DatabaseTasks.migrations_paths).needs_migration? ? 1 : 0)", chdir: app
    check("the databases are still the app's, not the directory's") do
      read(app, "config/database.yml").include?("database: #{name}_development") &&
        read(app, "docker-compose.yml").start_with?("name: #{name}\n")
    end
    # The name has digits, which the app's module cannot give back: reapply_123 is Reapply123.
    check("the app is still called what it was created as") { read(app, "AGENTS.md").lines.first == title }
    check("the app's menu group stays, and the components' groups are placed beside it") do
      controller = read(app, "app/controllers/application_controller.rb")
      controller.include?('submenu "Directory"') && controller.scan("include WulinComponents").one? &&
        read(app, "app/controllers/concerns/wulin_components.rb").include?('submenu "Settings"')
    end
    step "the components' menu groups and methods load", {}, "bin/rails", "runner",
      "WulinMaster::ScreenController.wulin_component_menus; exit(WulinMaster::ScreenController.method_defined?(:require_admin) ? 0 : 1)", chdir: app
    # wulin_permits' migrations create two views, which the test database -- loaded from db/schema.rb,
    # not migrated -- has only if the dump carries them.
    check("the schema holds wulin_permits' views") do
      %w[user_all_permissions permission_all_users].all? { |v| read(app, "db/schema.rb").include?(%(create_view "#{v}")) }
    end
    step "prepare the test database from the schema", {"RAILS_ENV" => "test"}, "bin/rails", "db:prepare", chdir: app
    step "the test database has the views", {"RAILS_ENV" => "test"}, "bin/rails", "runner",
      "exit((%w[user_all_permissions permission_all_users] - ActiveRecord::Base.connection.views).empty? ? 0 : 1)", chdir: app
    check("the app's own import and style are built along with every component's") do
      script, css = read(app, "app/assets/builds/application.js"), read(app, "app/assets/builds/application.css")
      read(app, "app/javascript/application.js").include?(%(import "./own")) && script.include?("appOwnScript") &&
        css.include?(".app-own-style") && css.include?("#action_btns")
    end
    commit app, "every component"

    step "re-apply again", ADMIN.merge("WULIN_COMPONENTS" => "all"),
      "bin/rails", "app:template", "LOCATION=#{TEMPLATE}", chdir: app
    changed = IO.popen(%w[git status --porcelain], chdir: app, &:read)
    abort "FAIL: a second re-apply changed\n#{changed}#{IO.popen(%w[git diff], chdir: app, &:read)}" unless changed.empty?
    puts "OK: a second re-apply changed nothing"

    # As an app made by a template that wrote the components' code into ApplicationController has it.
    edit(app, "app/controllers/application_controller.rb") { |text| text.sub(/^ *include WulinComponents\n/, "") }
    refused = IO.popen(GIT_ENV.merge(ADMIN, "WULIN_COMPONENTS" => "all"),
      ["bin/rails", "app:template", "LOCATION=#{TEMPLATE}"], chdir: app, err: [:child, :out], &:read)
    check("an app with the components' code inline is refused, not wired twice") do
      !$?.success? && refused.include?("does not include WulinComponents") &&
        IO.popen(%w[git status --porcelain], chdir: app, &:read) == " M app/controllers/application_controller.rb\n"
    end
  ensure
    system("bin/rails", "db:drop", chdir: app, out: File::NULL, err: File::NULL) if File.exist?(File.join(app, "bin/rails"))
  end
end
