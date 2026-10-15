#!/usr/bin/env ruby
# frozen_string_literal: true

# Can a component be added to an app that already exists, and does running the template again
# change nothing?
#
#   ruby script/check_reapply.rb
#
# Scaffolds an app with wulin_master alone and gives it two things an app made by an earlier template
# has: the admin seed that template wrote, unmarked, and React 18 installed but not declared, as npm
# left it when wulin_agent still brought React itself. Then re-applies the template for every
# component, as a component chosen later arrives, and checks that the first admin is the one
# ADMIN_EMAIL / ADMIN_PASSWORD name rather than the one that older seed creates, and that the app is
# still on its one React 18. Last, re-applies once more and requires a clean tree: a
# component template that appends, injects or overwrites without checking what is already there
# fails there.
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

Dir.mktmpdir("wulin_reapply") do |root|
  name = "reapply_#{Process.pid}"
  app = File.join(root, name)
  seeds = File.join(app, "db/seeds.rb")
  begin
    step "scaffold with wulin_master alone", {"WULIN_COMPONENTS" => ""},
      "rails", "new", name, "--quiet", *NEW_FLAGS, "-m", TEMPLATE, chdir: root
    File.write(seeds, "#{File.read(seeds)}\n#{LEGACY_SEED}")
    step "install React 18", {}, "npm", "install", "--silent", "react@18.3.1", "react-dom@18.3.1", chdir: app
    manifest = File.join(app, "package.json")
    package = JSON.parse(File.read(manifest))
    package["dependencies"] = package["dependencies"].except("react", "react-dom")
    File.write(manifest, "#{JSON.pretty_generate(package)}\n")
    commit app, "scaffold, with an earlier template's admin seed and an undeclared React 18"

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
    commit app, "every component"

    step "re-apply again", ADMIN.merge("WULIN_COMPONENTS" => "all"),
      "bin/rails", "app:template", "LOCATION=#{TEMPLATE}", chdir: app
    changed = IO.popen(%w[git status --porcelain], chdir: app, &:read)
    abort "FAIL: a second re-apply changed\n#{changed}#{IO.popen(%w[git diff], chdir: app, &:read)}" unless changed.empty?
    puts "OK: a second re-apply changed nothing"
  ensure
    system("bin/rails", "db:drop", chdir: app, out: File::NULL, err: File::NULL) if File.exist?(File.join(app, "bin/rails"))
  end
end
