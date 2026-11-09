# frozen_string_literal: true

# Read-only preflight for moving a wulin app onto the wulin_master v3 template.
#
#   ruby preflight.rb <app root>
#
# The wulin_master it compares against is the checkout this script ships in.
# Prints what the app has that the template will overwrite, ignore or refuse. A missing component,
# CI config, or deploy layout is reported and skipped -- the template apply does not need it.
require "json"
require "open3"
require "yaml"

abort "usage: preflight.rb <app>" unless ARGV.size == 1
app = File.expand_path(ARGV.first)
wm = File.expand_path("../../..", __dir__)
Dir.chdir(app)

def read(path)
  File.exist?(path) ? File.read(path) : nil
end

def section(title)
  puts "\n## #{title}"
end

def git(*args, dir:)
  out, status = Open3.capture2("git", "-C", dir, *args.map(&:to_s), err: File::NULL)
  status.success? ? out.strip : ""
end

template = File.read(File.join(wm, "template.rb"))
gemfile = read("Gemfile").to_s
lockfile = read("Gemfile.lock").to_s

def component_dirs(gemfile)
  dirs = Dir.glob("vendor/gems/wulin_*")
  read(".gitmodules").to_s.scan(/path = (\S+)/).flatten.each { |path| dirs << path }
  gemfile.scan(/^\s*gem ["']wulin_[a-z_]+["'].*\bpath:\s*["']([^"']+)["']/).flatten.each { |path| dirs << path }
  dirs.map { |dir| File.expand_path(dir) }.uniq.select { |dir|
    File.directory?(dir) && File.basename(dir).start_with?("wulin_")
  }
end

def lock_revisions(lockfile)
  lockfile.split(/^GIT\n/).filter_map { |block|
    name = block[/^\s+(wulin_[a-z_]+) \(/, 1]
    rev = block[/revision: (\h+)/, 1]
    [name, rev] if name && rev
  }.to_h
end

section("Ruby and Rails (the template refuses below 3.4 / 8.1)")
puts "  running Ruby #{RUBY_VERSION}; Gemfile.lock Ruby: #{lockfile[/RUBY VERSION\n\s+ruby (\S+)/, 1] || "unrecorded"}; .ruby-version: #{read(".ruby-version")&.strip || "none"}"
puts "  Gemfile.lock rails: #{lockfile[/^    rails \((\S+)\)/, 1]}"

section("Gemfile: wulin gems and how they are sourced")
gemfile.scan(/^\s*gem ["'](wulin_[a-z_]+)["'](.*)$/).each { |name, rest| puts "  #{name}#{rest}" }
catalog = template.scan(/\{name: "([^"]+)"/).flatten
unknown = gemfile.scan(/^\s*gem ["'](wulin_[a-z_]+)["']/).flatten - catalog
puts "  NOT IN TEMPLATE CATALOG: #{unknown.join(", ")} -- stays app-owned; link_wulin_gems.rb leaves a path gem in vendor/gems as it is" if unknown.any?
removed = template[/%w\[([^\]]+)\]\.each do \|name\|\s*\n\s*gsub_file "Gemfile"/m, 1]&.split
if removed
  present = removed.select { |name| gemfile.match?(/^\s*gem ["']#{name}["']/) }
  puts "  template REMOVES on every run: #{present.join(", ")}" if present.any?
else
  puts "  could not read the gem-removal list from this template.rb; check it before applying"
end
puts "  json < 3.0 missing (template adds it)" unless gemfile.match?(/gem ["']json["']/)
submodules = read(".gitmodules").to_s.scan(/path = (\S+)/).flatten
moved, kept = submodules.partition { |path| catalog.include?(File.basename(path)) }
puts "  submodules the template moves to git gems: #{moved.join(" ")}" if moved.any?
puts "  submodules that stay (not in the template catalog): #{kept.join(" ")}" if kept.any?

section("Component refs: checkout or Gemfile.lock vs components.lock.yml")
lock = YAML.safe_load_file(File.join(wm, "components.lock.yml")).fetch("components")
checkouts = component_dirs(gemfile)
if checkouts.empty?
  puts "  no local wulin checkout (looked in vendor/gems, .gitmodules, and Gemfile path: gems)"
end
seen = []
checkouts.sort.each do |dir|
  name = File.basename(dir)
  seen << name
  pin = lock[name]
  next puts("  #{name}: no pin in components.lock.yml (#{dir})") unless pin

  # A branch-tracked component (wulin_master) resolves to that branch's tip on the mirror the
  # template's Gemfile line points at, so that tip is what the app's commits are counted against.
  target = pin["ref"] || git("ls-remote", "https://github.com/ekohe/#{name}.git", "refs/heads/#{pin["branch"]}", dir: dir)[/\A\h{40}/]
  next puts("  #{name}: cannot read #{pin["branch"]}'s tip from github.com/ekohe/#{name}") unless target

  head = git("rev-parse", "HEAD", dir: dir)
  if head.empty?
    puts "  #{name}: #{dir} is not a git checkout; cannot count commits against the lock"
    next
  end
  app_only = git("rev-list", "--count", "#{target}..HEAD", dir: dir)
  lock_only = git("rev-list", "--count", "HEAD..#{target}", dir: dir)
  if app_only.empty?
    puts "  #{name}: lock ref #{target[0, 8]} is not in #{dir}; fetch before trusting this"
    next
  end
  flag = (app_only.to_i > 0) ? "  <-- LOCK WOULD DROP #{app_only} COMMIT(S)" : ""
  puts "  #{name}: app #{head[0, 8]} lock #{target[0, 8]} (#{pin["branch"]}) app-only=#{app_only} lock-only=#{lock_only}#{flag}"
end
lock_revisions(lockfile).each do |name, rev|
  next if seen.include?(name)

  pin = lock[name]
  next puts("  #{name}: Gemfile.lock #{rev[0, 8]}, no pin") unless pin
  if pin["ref"]
    flag = (rev == pin["ref"]) ? "" : "  <-- DIFFERS FROM LOCK #{pin["ref"][0, 8]} (no checkout to count commits)"
    puts "  #{name}: Gemfile.lock #{rev[0, 8]}#{flag}"
  else
    puts "  #{name}: Gemfile.lock #{rev[0, 8]}, lock tracks #{pin["branch"]}"
  end
end

section("Gem files the app overrides by path")
checkouts.each do |gem_dir|
  %w[app/views app/assets/javascripts app/assets/stylesheets app/grids app/screens app/controllers app/models app/panels].each do |sub|
    base = File.join(gem_dir, sub)
    next unless Dir.exist?(base)

    Dir.glob("**/*", base: base).each do |rel|
      next if File.directory?(File.join(base, rel))

      stem = rel.sub(/(\.[a-z]+)+\z/, "")
      Dir.glob(File.join(sub, "#{stem}.*")).each { |hit| puts "  #{File.basename(gem_dir)}: #{hit}" }
    end
  end
end

section("Reopened or patched wulin classes in app code")
Dir.glob("{app,config,lib}/**/*.rb").each do |file|
  File.foreach(file).with_index(1) do |line, n|
    next unless line.match?(/^\s*(class|module) (::)?Wulin|Wulin\w*(::\w+)*\.(send|class_eval|prepend|include)\b|\.send[ (]:include/)

    puts "  #{file}:#{n}: #{line.strip}"
  end
end

section("Legacy asset syntax")
Dir.glob("app/{assets,javascript}/**/*").select { |file| File.file?(file) && !file.start_with?("app/assets/builds/", "app/assets/fonts/") }.each do |file|
  puts "  #{file}: coffee" if file.end_with?(".coffee")
  File.foreach(file).with_index(1) do |line, n|
    next if line.strip.start_with?("//") && !line.include?("= require")

    puts "  #{file}:#{n}: #{line.strip}" if line.match?(/image-url|asset-url|asset-path|^\s*\/\/= require|^\s*\*= require/)
  end
rescue ArgumentError
  next
end

section("ApplicationController")
ac = read("app/controllers/application_controller.rb").to_s
concern = read("app/controllers/concerns/wulin_components.rb").to_s
puts "  include WulinComponents: #{ac.include?("include WulinComponents") ? "yes" : "NO -- template refuses to re-apply until it is"}"
filters = ac.scan(/before_action :(\w+)/).flatten
concern_filters = concern.scan(/before_action :(\w+)/).flatten
puts "  before_action order: #{filters.join(" -> ")}" if filters.any?
puts "  WulinComponents before_action order: #{concern_filters.join(" -> ")}" if concern_filters.any?
filters += concern_filters
if (login_at = filters.index("require_login")) && (user_at = filters.index("set_current_user")) && login_at < user_at
  puts "  BUG: set_current_user runs after require_login -- a redirected request is audited as the thread's previous user"
end
component_screens = checkouts.flat_map { |dir|
  Dir.glob(File.join(dir, "app/screens/**/*.rb")).flat_map { |file| File.read(file).scan(/class (\w+Screen)/).flatten }
}
listed = ac.scan(/item (\w+Screen)/).flatten & component_screens
puts "  component screens in the app's own menu (template adds its own groups for these): #{listed.uniq.join(", ")}" if listed.any?
puts "  other methods/constants: #{ac.scan(/^\s*(?:def (?:self\.)?(\w+)|([A-Z_]{3,}) =)/).flatten.compact.join(", ")}"

section("Files the template owns (rewritten on every run) that the app already has")
{
  "Procfile.dev" => nil, "bin/dev" => nil, "config/puma.rb" => "(gitignored here?)",
  "app/javascript/wulin_components.js" => nil, "app/assets/stylesheets/_wulin_components.sass" => nil,
  "app/controllers/concerns/wulin_components.rb" => nil, "script/link_wulin_gems.rb" => nil,
  "script/copy_material_icons.js" => nil,
  "config/app_config_loader.rb" => "(an app's own loader options are lost: keep them in a file of the app's)",
  "app/javascript/wulin_oauth.js" => nil, "app/assets/stylesheets/wulin_oauth.sass" => nil,
  "app/javascript/wulin_auth.js" => nil, "app/assets/stylesheets/wulin_auth.sass" => nil
}.each { |path, note| puts "  #{path}#{" #{note}" if note}" if File.exist?(path) }
pkg = read("package.json")
if pkg
  scripts = JSON.parse(pkg)["scripts"] || {}
  puts "  package.json scripts the template replaces: #{(scripts.keys & %w[build build:watch copy-icons]).join(", ")}"
end
puts "  yarn.lock present -- template removes it and uses npm" if File.exist?("yarn.lock")

section("Shared files: is the template's anchor there?")
assets = read("config/initializers/wulin_master_assets.rb").to_s
builds = 'config.dartsass.builds = {"application.sass" => "application.css"}'
puts "  wulin_master_assets.rb #{assets.include?(builds) ? "has" : "LACKS"} the builds line components inject after -- #{assets.empty? ? "missing (template writes it)" : "replace it with the template's"}"
puts "  config/app_config.example.yml: #{File.exist?("config/app_config.example.yml") ? "present -- the template treats the app as scaffolded before" : "absent -- the template treats the app as NEW (overwrites database.yml, README)"}"
example = read("config/app_config.example.yml").to_s
puts "  app_config.example.yml wulin_master section: #{example.match?(/^wulin_master:/) ? "yes" : "no (template appends one)"}"
puts "  config/initializers/wulin_master.rb: #{File.exist?("config/initializers/wulin_master.rb") ? "kept as the app's (template writes one only when missing)" : "missing"}"
agents = read("AGENTS.md").to_s
agents_state = if agents.empty?
  "absent"
elsif agents.include?("<!-- wulin:begin agents")
  "has the block"
else
  "app's own -- block will be appended"
end
puts "  AGENTS.md: #{agents_state}"
puts "  Dockerfile.dev: #{File.exist?("Dockerfile.dev") ? "present (stack kept)" : "absent (stack skipped by default on re-apply)"}"
puts "  bin/setup: #{File.exist?("bin/setup") ? "present (template injects link + npm install after bundle install)" : "absent"}"
puts "  application entry points: #{Dir.glob("app/javascript/*.js").join(" ")} | #{Dir.glob("app/assets/stylesheets/{application.*,wulin/*}").join(" ")}"

section("Anchors the template injects at (a miss is silent)")
envs = Dir.glob("config/environments/*.rb").reject { |file| File.read(file).include?("Rails.application.configure do") }
puts "  config/environments not opened with `Rails.application.configure do` (DebugLocks lands nowhere): #{envs.join(" ")}" if envs.any?
setup = read("bin/setup").to_s
puts "  bin/setup lacks `system(\"bundle check\") || system!(\"bundle install\")` -- replace it with Rails 8.1's, or the link/npm/build steps are not added" unless setup.include?(%(system("bundle check") || system!("bundle install")))
app_rb = read("config/application.rb").to_s
puts "  config/application.rb defines APP_CONFIG itself -- remove that block; the template injects AppConfigLoader and two definitions warn" if app_rb.include?("APP_CONFIG =") && !app_rb.include?("AppConfigLoader.load")
puts "  .gitignore does not ignore .env -- the template copies .env.example to .env" unless read(".gitignore").to_s.match?(%r{^/?\.env})
db = [read("config/database.yml"), read("config/database.example.yml")].compact.join("\n")
puts "  no gssencmode: disable in database.yml -- add it for macOS with libpq 18 (Solid Queue workers segfault). Other platforms skip this." unless db.include?("gssencmode")

section("Lint config that walks node_modules (the npm workspace links into the installed gem)")
standard = read(".standard.yml").to_s
if standard.match?(/default_ignores:\s*false/) && !standard.include?("node_modules")
  puts "  .standard.yml: default_ignores is off -- add node_modules/**/* to its ignores, or `standard:fix` rewrites the wulin_master gem"
end

section("app_config files: every one gets the wulin_master key")
# Tracked files only: a gitignored config/app_config.yml is a local copy, not one to update.
git("ls-files", "config", dir: app).split("\n").grep(/app_config[^\/]*\.yml\z/).sort.each do |file|
  text = File.read(file)[/^wulin_master:\n(?:[ #].*\n)*/]
  puts(text ? "  #{file}:\n#{text.gsub(/^/, "      ")}" : "  #{file}: no wulin_master section")
end
git("ls-files", "config", dir: app).split("\n").grep(/app_config[^\/]*\.yml\.enc\z/).sort.each do |file|
  puts "  #{file}: encrypted -- needs its key to edit"
end
init = read("config/initializers/wulin_master.rb").to_s
puts "  config/initializers/wulin_master.rb assigns settings -- move them to the wulin_master key, then delete it so the template writes its APP_CONFIG version" if init.match?(/config\.\w+\s*=/) && !init.include?("APP_CONFIG")

section("Secrets committed in example configs")
Dir.glob("config/*.example.{yml,yaml}").each do |file|
  File.foreach(file).with_index(1) do |line, n|
    next unless line.match?(/(secret|password|identifier)\s*:\s*["']?[A-Za-z0-9+\/]{20,}/i)

    puts "  #{file}:#{n}: #{line.strip.sub(/:\s*(\S{6})\S+/, ': \1…')}"
  end
end

section("Deploy and CI (absent means this step does not apply)")
cap = read("Capfile").to_s
puts "  Capfile: #{if cap.empty?
                     "absent"
                   elsif cap.match?(/submodule/)
                     "uses a submodule strategy"
                   else
                     "present, no submodule strategy"
                   end}"
puts "  config/deploy.rb: #{File.exist?("config/deploy.rb") ? "present" : "absent"}"
ci = Dir.glob("{.gitlab-ci.yml,.github/workflows/*.{yml,yaml},.circleci/config.yml,bitbucket-pipelines.yml,Jenkinsfile}")
if ci.empty?
  puts "  no CI config in the usual places"
else
  ci.each do |file|
    text = File.read(file)
    flags = []
    flags << "submodule" if text.include?("submodule")
    flags << "yarn" if text.include?("yarn")
    puts "  #{file}: #{flags.empty? ? "no submodule or yarn step" : flags.join(", ")}"
  end
end
lib_tasks = Dir.glob("lib/tasks/*.rake").select { |file| File.read(file).match?(/assets|dartsass|yarn|npm/) }
puts "  lib/tasks touching assets: #{lib_tasks.join(" ")}"
