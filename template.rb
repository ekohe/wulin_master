# rails new APP_NAME --skip-hotwire --skip-solid --database=postgresql --skip-javascript -m ./template.rb
#
# Asks which Wulin components to install, then vendors and configures each one. Set
# WULIN_COMPONENTS to skip the questions:
#
#   WULIN_COMPONENTS=all rails new ... -m ./template.rb
#   WULIN_COMPONENTS=wulin_audit,wulin_excel rails new ... -m ./template.rb

# `rails app:template LOCATION=...` re-applies this to an app that exists, which is how a component
# SELECTED LATER arrives. The steps that CREATE the app are skipped on this flag: they append a line
# or claim a file, so a second run would write it twice.
#
# It answers "has this template run HERE before", not "is there an app here" -- the file it names is
# one this template writes, so a Rails app built some other way is scaffolded into. Read at the top,
# before anything is written, because that file is created further down.
@wulin_scaffolded_before = File.exist?("config/app_config.example.yml")

# The flags in the command above are the ones this template depends on. A run without one is
# refused before this template changes anything, rather than finishing as a broken app. `rails new`
# has already written the app by then, so it has to be removed before running again. Not on a
# re-apply: `rails app:template` hands this file Rails' default options, so there is no flag to read,
# and what each one protects was settled when the app was created:
#
# --skip-javascript  This template owns the JavaScript build -- package.json, Procfile.dev, bin/dev
#                    and app/assets/builds -- and any other choice installs a second one between
#                    this body and after_bundle: importmap's pins, or a jsbundling installer that
#                    rewrites those files with whatever package manager it finds (under Yarn 4, a
#                    Plug'n'Play manifest esbuild then resolves through, so no gem import resolves).
# --skip-solid       wulin_queue owns Solid Queue's schema in the primary database. Without the flag
#                    Rails writes a production database.yml for four databases and runs Solid's
#                    installers.
# --database=...     wulin_audit's tables use jsonb columns.
missing = {
  "--skip-javascript" => options[:skip_javascript],
  "--skip-solid" => options[:skip_solid],
  "--database=postgresql" => options[:database] == "postgresql"
}.reject { |_, given| given }.keys
if missing.any? && !@wulin_scaffolded_before
  raise Thor::Error, "This template needs `rails new` run with #{missing.join(" ")} -- the header of " \
    "template.rb says why. Remove the generated app and run it again."
end

require "json"
require "open-uri"
require "shellwords"
require "yaml"

# Applied over a URL, this file's __FILE__ *is* that URL, so File.read cannot reach the
# component templates next to it.
@wulin_source = File.dirname(__FILE__)
@wulin_remote_source = @wulin_source.match?(%r{\Ahttps?://})

# Remove gems we don't use. These blocks shape the Gemfile `rails new` wrote, so on a re-apply
# they have nothing left to do -- except where one of these gems was put back on purpose, which this
# removes again, in whatever group it was written: the pattern matches the line, not the block.
%w[debug rubocop-rails-omakase web-console capybara selenium-webdriver tzinfo-data].each do |name|
  gsub_file "Gemfile", /^.*gem "#{name}".*\n/, ""
end

# Strip empty group blocks left behind after removing gems.
gsub_file "Gemfile", /^group :[^\n]+\n(#[^\n]*\n|\s*\n)*end\n/, ""

# RSpec and factory_bot are every app's test stack, whichever components it selects.
unless @wulin_scaffolded_before
  gem_group :development, :test do
    gem "standard"
    gem "rspec-rails"
    gem "factory_bot_rails"
  end
end

# What the components ARE. Which code they resolve to is `components.lock.yml` beside this file --
# the split a Gemfile and a Gemfile.lock make, so nothing is stated in both places.
#
# Install order, and it matters: wulin_permits must land before wulin_queue so the Permission model
# exists when the queue migrations seed it.
@wulin_catalog = [
  {name: "wulin_master", required: true,
   summary: "grids, screens, menus, the esbuild/dart-sass pipeline"},
  {name: "wulin_auth",
   summary: "login/logout, current_user, password reset"},
  {name: "wulin_permits", needs: %w[wulin_auth],
   summary: "users, roles, privileges, per-screen permissions"},
  {name: "wulin_queue", needs: %w[wulin_permits],
   summary: "Solid Queue job screens: pending, failed, scheduled, processes"},
  {name: "wulin_audit",
   summary: "audit trail for every model write, plus request action logs"},
  {name: "wulin_excel",
   summary: "Excel export button on grid toolbars"},
  {name: "wulin_agent", needs: %w[wulin_permits],
   summary: "AI assistant over the grids: in-app chat and an MCP endpoint"}
]

# The component templates fill these in; this file assembles them at the end.
# All of them are written unindented -- wulin_indent puts them where they go.
@wulin_js = []           # paths to import from app/javascript/application.js
@wulin_sass = []         # indented-Sass rules for application.sass
@wulin_menus = []        # submenu blocks for ApplicationController.define_menu
@wulin_filters = []      # before_action lines ApplicationController must run
@wulin_methods = []      # methods ApplicationController must define
@wulin_app_config = []   # YAML sections for config/app_config.yml
@wulin_post = []         # runs after bundle, before the database is set up
@wulin_db_post = []      # runs after db:migrate, for anything needing tables
@wulin_notes = []        # printed last, once everything has run, and kept in AGENTS.md
@wulin_run_notes = []    # printed last too, but about this run only, so kept nowhere
@wulin_workspaces = []   # npm workspaces besides wulin_master's, for components with npm dependencies
@wulin_npm = {}          # packages the app itself depends on, for components' npm peer dependencies
@wulin_entries = []      # esbuild entry points besides app/javascript/application.js

# A file shipping next to this template, read from disk or over HTTPS depending on how
# the template itself arrived.
def wulin_read(relative)
  path = "#{@wulin_source}/#{relative}"
  @wulin_remote_source ? URI.parse(path).open(&:read) : File.read(path)
end

# `components.lock.yml`, read beside this file -- over HTTPS when this template arrived that way,
# exactly like the component templates. Memoized: one read per scaffold, not one per component.
def wulin_lock
  @wulin_lock ||= YAML.safe_load(wulin_read("components.lock.yml")).fetch("components")
rescue => e
  raise Thor::Error,
    "could not read components.lock.yml beside this template (#{@wulin_source}): #{e.class}: #{e.message}. " \
    "It names the commit each component is vendored at, and nothing else does."
end

def wulin_vendor(name)
  component = @wulin_catalog.find { |c| c[:name] == name }
  pin = wulin_lock[name] or
    raise Thor::Error, "#{name} is in the catalog but not in components.lock.yml -- nothing says which commit to install"
  # Written back so templates/README.md.erb reports what was installed.
  branch = component[:branch] = pin.fetch("branch")
  ref = pin["ref"]&.to_s
  say_status :component, "#{name} (#{ref ? ref[0, 8] : branch})", :green

  # `github:` is public HTTPS, not the GitLab mirror over SSH: the generated app is delivered to
  # GitHub, where git@gitlab.ekohe.com is unclonable without a key -- including by its image build.
  #
  # wulin_master carries a branch and no ref on purpose: it is this repository, served from the same
  # branch as the gem it vendors.
  #
  # A pinned component gets its ref and no branch. Given both, Bundler 2.6 clones only the branch's
  # tip, depth 1, and then cannot find the ref in that clone once the branch has moved past it: every
  # fresh install fails with "not our ref". So `bundle config local.<name>` does not apply to these;
  # point the line at the checkout with `path:` while editing the gem.
  #
  # `gem` APPENDS and bundler refuses the same gem twice, so a changed declaration replaces the old
  # one -- which is how a moved pin lands. An unchanged one is left where it is, so re-applying the
  # template is no change to the Gemfile.
  source = ref ? {github: "ekohe/#{name}", ref: ref} : {github: "ekohe/#{name}", branch: branch}
  line = %(gem "#{name}", ) + source.map { |key, value| "#{key}: #{value.inspect}" }.join(", ")
  return if File.read("Gemfile").lines.map(&:chomp).include?(line)

  gsub_file "Gemfile", /^gem "#{name}",.*\n/, "", verbose: false
  gem name, **source
end

# Re-applying runs every component template again, over files the first run wrote and
# `standardrb --fix` then reformatted -- so Thor's own duplicate check, which compares text exactly,
# misses. Writes into a file the app already has are keyed on something the first write left in it.
#
# A gem the Gemfile already declares, by an earlier run or by the app, is left as it is -- it may be
# the app's own choice -- and a requirement this template asks for that the declaration lacks is
# noted rather than imposed.
def wulin_gem(name, *args, **opts)
  declared = File.read("Gemfile")[/^\s*gem ["']#{Regexp.escape(name)}["'].*$/]
  return gem(name, *args, **opts) unless declared

  wanted = args.map(&:inspect) + opts.map { |key, value| "#{key}: #{value.inspect}" }
  missing = wanted.reject { |part| declared.include?(part) }
  wulin_note "Gemfile declares #{name} without #{missing.join(", ")}, which this template asks for -- left as it is" if missing.any?
end

def wulin_written?(path, marker)
  File.exist?(path) && File.read(path).include?(marker)
end

# A block this template owns inside a file the app writes to as well, replaced whole on every run. It
# is found by `# wulin:begin <id>` and `# wulin:end <id>` alone, so the explanation after the first
# marker may change between versions of this template; the id may not.
#
# The first time, it is appended -- or, with `ahead: true`, put after the file's leading comments and
# ahead of any code or other block, for a block that has to run before whatever the app already does.
def wulin_block(path, id, content, ahead: false)
  body = "# wulin:begin #{id} -- rewritten when the template is re-applied; edit outside it\n" \
    "#{content}# wulin:end #{id}\n"
  block = /^# wulin:begin #{Regexp.escape(id)}(?: [^\n]*)?\n.*?^# wulin:end #{Regexp.escape(id)}\n/m
  text = File.exist?(path) ? File.read(path) : ""
  return create_file(path, text.sub(block) { body }, force: true) if text.match?(block)

  header = ahead ? text[/\A(?:[ \t]*(?:#(?! wulin:begin ).*)?\n)*/] : text
  parts = [header, body, text.delete_prefix(header)].map(&:strip).reject(&:empty?)
  create_file path, "#{parts.join("\n\n")}\n", force: true
end

# package.json is the app's as much as this template's. A workspace or a package the template needs is
# added when missing, and the app's own version of one is kept; the scripts given here are the
# template's and rewritten. Everything else in the file is left as the app has it.
def wulin_package_json(package)
  if File.exist?("package.json")
    app = JSON.parse(File.read("package.json"))
    # A package the app has installed without declaring it -- npm put it there as a workspace's peer --
    # is declared at the version installed, not at the template's: re-applying this does not move an app
    # on React 18 to 19.
    installed = File.exist?("package-lock.json") ? JSON.parse(File.read("package-lock.json")).fetch("packages", {}) : {}
    as_installed = ->(deps) { deps.to_h { |name, range| [name, installed.dig("node_modules/#{name}", "version")&.then { |version| "^#{version}" } || range] } }
    package = app.merge(
      "workspaces" => app.fetch("workspaces", []) | package["workspaces"],
      "dependencies" => as_installed.call(package["dependencies"]).merge(app.fetch("dependencies", {})),
      "devDependencies" => as_installed.call(package["devDependencies"]).merge(app.fetch("devDependencies", {})),
      "scripts" => app.fetch("scripts", {}).merge(package["scripts"])
    )
  end
  create_file "package.json", "#{JSON.pretty_generate(package)}\n", force: true
end

def wulin_js(*paths)
  @wulin_js.concat(paths)
end

def wulin_sass(rules)
  @wulin_sass << rules
end

def wulin_menu(block)
  @wulin_menus << block
end

def wulin_filter(code)
  @wulin_filters << code
end

def wulin_method(code)
  @wulin_methods << code
end

def wulin_post(&block)
  @wulin_post << block
end

def wulin_db_post(&block)
  @wulin_db_post << block
end

# What anyone working on the app should know. `run: true` for what only this run did -- the app's
# documents are rewritten on every run and would lose it on the next one.
def wulin_note(text, run: false)
  (run ? @wulin_run_notes : @wulin_notes) << text
end

# A component whose JavaScript imports npm packages of its own. Its package.json joins the app's
# workspaces, so `npm install` puts those packages in the app's node_modules, where the app's esbuild
# resolves them -- the same way wulin_master's jQuery and Materialize arrive.
def wulin_workspace(path)
  @wulin_workspaces << path
end

# A package the app itself must depend on: a workspace's peer dependency, which the bundle has to
# hold exactly once (React). npm would install a missing peer on its own, but at whatever version
# the peer range allows; declared here it is the app's, and an app's own version of it is kept.
def wulin_npm(packages)
  @wulin_npm.merge!(packages)
end

# A page that loads a bundle of its own rather than application.js -- the login page.
def wulin_entry(path)
  @wulin_entries << path
end

def wulin_app_config(yaml)
  @wulin_app_config << yaml
end

def wulin_indent(blocks, spaces)
  blocks.map { |block|
    block.lines.map { |line| line.strip.empty? ? line : (" " * spaces) + line }.join
  }.join("\n")
end

# What an app that already exists declares for itself. The assembly rewrites application.js, the Sass
# entry and ApplicationController from the FULL set, so a re-applied template told only about the new
# component would strip the wiring of every other one. The Gemfile is the authority: it is what
# bundler resolves, and what a dependency step appends to.
def wulin_declared
  return [] unless @wulin_scaffolded_before

  known = @wulin_catalog.map { |c| c[:name] }
  File.read("Gemfile").scan(/^gem "(wulin_[a-z_]+)"/).flatten & known
rescue Errno::ENOENT
  []
end

def wulin_selection
  requested = ENV["WULIN_COMPONENTS"].to_s.strip
  optional = @wulin_catalog.reject { |c| c[:required] }

  chosen = if requested == "all"
    optional.map { |c| c[:name] }
  elsif !requested.empty?
    requested.split(",").map(&:strip).reject(&:empty?)
  elsif $stdin.tty?
    optional.select { |c| yes?("Install #{c[:name]}? (#{c[:summary]}) [y/N]") }.map { |c| c[:name] }
  else
    # Asking a closed stdin reads EOF and answers no to everything, which looks like a
    # successful build of an app missing every optional component.
    say_status :components, "stdin is not a tty and WULIN_COMPONENTS is unset -- installing only #{@wulin_catalog.select { |c| c[:required] }.map { |c| c[:name] }.join(", ")}", :yellow
    []
  end

  chosen |= wulin_declared

  unknown = chosen - @wulin_catalog.map { |c| c[:name] }
  raise Thor::Error, "Unknown component: #{unknown.join(", ")}" if unknown.any?

  # A component's `needs` are code dependencies, not suggestions -- wulin_queue's grids call
  # current_user.has_permission_with_name? and its migration seeds Permission rows, both of which
  # come from wulin_permits, whose own grids reference the User wulin_auth owns.
  #
  # `each` over the array being appended to, not a copy of it: it walks by index against the current
  # length, so a dependency added here is visited too and the chain is followed to its end.
  chosen.each do |name|
    @wulin_catalog.find { |c| c[:name] == name }[:needs].to_a.each do |dep|
      next if chosen.include?(dep)
      chosen << dep
      say "  + #{dep} (#{name} needs it to run)", :yellow
    end
  end

  @wulin_catalog.select { |c| c[:required] || chosen.include?(c[:name]) }
end

@wulin_install = wulin_selection

@wulin_install.each do |component|
  path = "templates/#{component[:name]}.rb"
  instance_eval(wulin_read(path), path)
end

# The development stack, which every app gets. After the components: the image it writes
# depends on which path gems ended up in the Gemfile.
instance_eval(wulin_read("templates/docker.rb"), "templates/docker.rb")

# --- assembly, once every component has had its say ------------------------

# app_config.yml holds real credentials in a deployed app, so it is gitignored
# and app_config.example.yml is what gets committed. Both start identical.
app_config = <<~YAML + @wulin_app_config.map(&:strip).join("\n\n") + "\n"
  # Read through APP_CONFIG, loaded in config/application.rb.
  #
  # This file is gitignored because it holds credentials in a deployed app.
  # Commit your changes to config/app_config.example.yml instead, and copy that
  # back to config/app_config.yml on a fresh checkout.

  time_zone: UTC

YAML

unless @wulin_scaffolded_before
  create_file "config/app_config.yml", app_config
  create_file "config/app_config.example.yml", app_config
  append_to_file ".gitignore", "\n/config/app_config.yml\n"
end

# On a re-apply the files are the app's own, edited and holding credentials, so only the section of a
# component they do not mention yet is appended -- the way a component selected later brings its
# settings with it.
if @wulin_scaffolded_before
  %w[config/app_config.example.yml config/app_config.yml].each do |path|
    next unless File.exist?(path)

    @wulin_app_config.each do |section|
      key = section[/^#?\s*(wulin_[a-z_]+):/, 1]
      next if key.nil? || File.read(path).match?(/^#?\s*#{key}:/)

      append_to_file path, "\n#{section.strip}\n"
    end
  end
end

after_bundle do
  # A Bundler git gem lives under a path carrying a commit SHA, which differs between host and
  # container and changes on every bump. esbuild, dart-sass and this template's own conventions all
  # address the components as `vendor/gems/<name>`, so that stable path is linked at the real
  # checkout. Derived, so it is gitignored — and rebuilt by the image build after every
  # `bundle install`, because the SHA in the path is exactly what a bump changes.
  file "script/link_wulin_gems.rb", <<~RB, force: true
    # The wulin components are Bundler git gems, so they live under a path that carries a commit SHA
    # and differs between host and container. esbuild, dart-sass and the app's own JavaScript all
    # resolve them as `vendor/gems/<name>`, so link that stable path at the real checkout.
    #
    # Run after `bundle install`, before `npm run build`:
    #
    #   bundle exec ruby script/link_wulin_gems.rb
    require "bundler"
    require "fileutils"

    target = File.expand_path("../vendor/gems", __dir__)
    FileUtils.mkdir_p(target)

    specs = Bundler.load.specs.select { |s| s.name.start_with?("wulin_") }
    abort("no wulin gems in the bundle — run bundle install first") if specs.empty?

    specs.each do |spec|
      link = File.join(target, spec.name)
      FileUtils.rm_rf(link)
      FileUtils.ln_s(spec.full_gem_path, link)
      puts "\#{spec.name} -> \#{spec.full_gem_path}"
    end
  RB
  unless @wulin_scaffolded_before
    append_to_file ".gitignore", <<~IGNORE

      # The wulin components are Bundler git gems; vendor/gems is symlinks built by
      # script/link_wulin_gems.rb, so it is derived and never committed.
      /vendor/gems
    IGNORE
  end
  run "bundle exec ruby script/link_wulin_gems.rb", abort_on_failure: true

  # bin/setup is how a fresh clone gets going, and on its own it would leave vendor/gems empty and
  # node_modules missing, so the first build cannot resolve a single component import.
  inject_into_file "bin/setup", after: /^  system\("bundle check"\) \|\| system!\("bundle install"\)\n/ do
    <<-RUBY
  system!("bundle exec ruby script/link_wulin_gems.rb")
  system!("npm install")
    RUBY
  end

  # wulin_master:install writes its own ApplicationController with a stub menu,
  # so this has to come after it and replace the file wholesale. Skipped on an app that exists: it
  # also copies a homepage controller and prepends a root route, and a second root is a route the
  # router never reaches behind the one already there.
  rails_command "generate wulin_master:install" unless @wulin_scaffolded_before

  # The app's test stack, set up once: a re-applied template would remove a test/ the app now owns
  # and append the support loader a second time.
  unless @wulin_scaffolded_before
    # RSpec is the test framework whatever `rails new` was passed: without --skip-test it also wrote
    # Minitest's test/, which nothing here runs.
    remove_dir "test"
    rails_command "generate rspec:install"

    # What `rspec:install` leaves undone: factory_bot's syntax methods are not included, and the
    # support-file loader in rails_helper is commented out, so `create(:thing)` raises NoMethodError.
    # The loader is appended, not uncommented: its commented line has moved between rspec-rails
    # versions, and `uncomment_lines` on a pattern that no longer matches silently does nothing.
    append_to_file "spec/rails_helper.rb", <<~RB

      # Loads spec/support (rspec:install ships this line commented out).
      Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }
    RB

    file "spec/support/factory_bot.rb", <<~RB
      # frozen_string_literal: true

      RSpec.configure do |config|
        config.include FactoryBot::Syntax::Methods
      end
    RB

    # CI runs the same specs. Rails points its CI at `bin/rails test`, which with test/ gone passes having
    # run nothing, and at system tests, which need the Capybara this template removes: config/ci.rb
    # (Rails 8.1+) always, the GitHub workflow unless --skip-ci -- 8.0 runs `test test:system` in one
    # job, 8.1 adds a separate system-test job. With --skip-test neither file has a test step; ci.rb
    # gets one, the workflow does not, as that would mean writing a whole job.
    if File.exist?("config/ci.rb")
      gsub_file "config/ci.rb", /^ *step "Tests: Rails".*\n/, ""
      gsub_file "config/ci.rb", /^ *# Optional: Run system tests\n *# step "Tests: System".*\n\n?/, ""
      inject_into_file "config/ci.rb", <<~STEPS.gsub(/^/, "  "), after: /\A.*^  step [^\n]*\n/m
        step "Build: assets", "bin/rails javascript:build dartsass:build"
        step "Tests: RSpec", "bundle exec rspec"
      STEPS
    end
    workflow = ".github/workflows/ci.yml"
    if File.exist?(workflow)
      gsub_file workflow, %r{run: bin/rails db:test:prepare test(?: test:system)?\n},
        "run: bin/rails db:test:prepare javascript:build dartsass:build && bundle exec rspec\n"
      gsub_file workflow, /\n+  system-test:\n(?: {4}.*\n|\n)*\z/, "\n"

      # npm resolves the components' workspaces through vendor/gems, which is not committed, so the
      # links come first -- and need no Rails, unlike the builds above, which run where RAILS_ENV and
      # DATABASE_URL are already set.
      link_step = "      - name: Link the wulin components\n" \
                  "        run: bundle exec ruby script/link_wulin_gems.rb\n\n"
      gsub_file(workflow, /^      - name: Run tests\n/) { |run_tests| link_step + run_tests }
    end
  end

  # `app/screens` and `app/grids` from the start, even before anything lives in them. Rails builds
  # its autoload paths from the directories under `app/` that exist AT BOOT, so a directory the
  # first `wulin_master:screen_and_grid` creates is invisible to the already-running server: the
  # class does not resolve and the route 404s, while specs pass throughout, each run being a fresh
  # boot that does see it.
  #
  # `.keep`, not `empty_directory`: git does not track an empty directory, so it would be gone from
  # the next clone and the image build that copies from it.
  create_file "app/screens/.keep"
  create_file "app/grids/.keep"

  file "app/javascript/application.js", <<~JS, force: true
    // wulin_master must be first: the other components attach to its globals
    // (WulinMaster.actions, gridManager, Ui, displayErrorMessage) at load time.
    #{@wulin_js.map { |path| "import \"#{path}\"" }.join("\n")}
  JS

  # Sass refuses an @use after any other rule, and the components arrive in catalog order -- so
  # wulin_permits' inline rules would otherwise land between wulin_master's @use and a later
  # component's. Every @use goes first; the order within each group is kept.
  #
  # One block, one kind: a block that opened with @use and then declared rules would be sorted with
  # the @uses and put its rules back in front of the next component's. A component contributing both
  # calls wulin_sass twice.
  uses, rules = @wulin_sass.map(&:strip).partition { |block| block.start_with?("@use ") }
  file "app/assets/stylesheets/application.sass",
    (uses + rules).join("\n\n") + "\n", force: true

  # Assembled already in standard's shape -- a component with nothing to add leaves no blank line
  # behind -- because a re-apply rewrites this file and does not run the formatter over the app.
  controller_body = [
    ["protect_from_forgery with: :exception", *@wulin_filters].join("\n"),
    *@wulin_methods.map(&:strip),
    "def self.define_menu\n  menu do |c|\n#{wulin_indent(@wulin_menus.map { |block| "#{block.strip}\n" }, 4)}  end\nend"
  ].join("\n\n")
  file "app/controllers/application_controller.rb", <<~RB + wulin_indent([controller_body], 2) + "\nend\n", force: true
    # frozen_string_literal: true

    class ApplicationController < ActionController::Base
  RB

  @wulin_post.each(&:call)

  # Build assets after all wulin_post blocks have run, so every component's
  # esbuild entries and dartsass config changes are in place.
  run "npm run build", abort_on_failure: true
  rails_command "dartsass:build", abort_on_failure: true

  # Every engine appends its own db/migrate to the app's migration paths, so a
  # plain db:migrate picks all of them up -- nothing needs install:migrations.
  rails_command "db:create db:migrate"

  # Components append to db/seeds.rb -- wulin_auth's admin user, for one. Rails' own file holds
  # only comments, so this is a no-op when none of them did.
  rails_command "db:seed"

  @wulin_db_post.each(&:call)

  # README.md belongs to whoever created the repository, which may already have written one. So the
  # generated description always goes to docs/wulin_app.md, and claims README.md only while it is
  # still Rails' placeholder, and only when the app is created: on a re-apply it is the app's.
  # AGENTS.md is this template's own file either way, and is rendered last so it carries the note
  # about a README that is not the generated one.
  #
  # The committed README counts, not only the file on disk: `rails new . --force` into a repository
  # that already has one has replaced it with Rails' placeholder before this runs.
  render = ->(name) { ERB.new(wulin_read("templates/#{name}.erb"), trim_mode: "-").result(binding) }
  readme = render.call("README.md")
  file "docs/wulin_app.md", readme, force: true

  unless @wulin_scaffolded_before
    placeholder = ->(text) { text.strip.empty? || text.include?("Things you may want to cover:") }
    committed = File.exist?(".git") ? `git show HEAD:README.md 2>/dev/null` : ""
    on_disk = File.exist?("README.md") ? File.read("README.md") : ""
    if !placeholder.call(committed)
      file "README.md", committed, force: true
    elsif placeholder.call(on_disk)
      file "README.md", readme, force: true
    end
  end
  # Off what the files say, not what this run did, so the next run writes the same AGENTS.md.
  unless File.exist?("README.md") && File.read("README.md") == readme
    wulin_note "README.md is not what this template writes -- that is docs/wulin_app.md, rewritten on every run"
  end

  file "AGENTS.md", render.call("AGENTS.md"), force: true

  # Rails writes STDOUT here; standard wants $stdout and classes the rewrite unsafe, so
  # `--fix` leaves it. They are the same object, and it is the one offence below that the
  # formatter cannot clear.
  gsub_file "config/environments/production.rb", "logger(STDOUT)", "logger($stdout)"

  # The generated app declares `standard`, and Rails writes its files for
  # rubocop-rails-omakase -- 23 offences in a bare `rails new`. This is where the two meet.
  # Only when the app is created: on a re-apply the code is the app's own, and adding a component is
  # no reason to reformat it. `|| true` because the exit code says what is left to tidy, not whether
  # the app works.
  run "bundle exec standardrb --fix || true" unless @wulin_scaffolded_before

  say "\nWulin components installed: #{@wulin_install.map { |c| c[:name] }.join(", ")}", :green
  (@wulin_notes + @wulin_run_notes).each { |note| say "  - #{note}", :yellow }
end
