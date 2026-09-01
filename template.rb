# rails new APP_NAME --skip-hotwire --skip-solid --database=postgresql --skip-javascript -m ./template.rb
#
# Asks which Wulin components to install, then vendors and configures each one. Set
# WULIN_COMPONENTS to skip the questions:
#
#   WULIN_COMPONENTS=all rails new ... -m ./template.rb
#   WULIN_COMPONENTS=wulin_audit,wulin_excel rails new ... -m ./template.rb
#
# Forge/AIDA runs a copy of that command verbatim (build contract: `scaffold`), so keep
# the two in sync. Two of its flags are load-bearing:
#
# --skip-solid: Rails 8 would otherwise put Solid Queue in a separate queue database,
# while wulin_queue creates the same tables in the primary one.
#
# --skip-javascript: this template owns package.json, Procfile.dev, bin/dev and
# app/assets/builds, and `-j esbuild` runs jsbundling's installer in between the body and
# after_bundle, overwriting two of them. That path still works; this one is supported.

require "open-uri"
require "shellwords"

# Applied over a URL, this file's __FILE__ *is* that URL, so File.read cannot reach the
# component templates next to it. AIDA always scaffolds over a URL.
@wulin_source = File.dirname(__FILE__)
@wulin_remote_source = @wulin_source.match?(%r{\Ahttps?://})

# GitHub over public HTTPS, not the GitLab mirror over SSH: this URL lands in the
# generated app's .gitmodules, and that app is delivered to GitHub, where
# git@gitlab.ekohe.com is unclonable without a key -- including by its own image build.
@wulin_git_base = "https://github.com/ekohe"

# Install order, and it matters: wulin_permits must land before wulin_queue so the
# Permission model exists when the queue migrations seed it.
#
# `branch` pins a component; without one it tracks the repository's default branch.
# wulin_master is pinned because the gem's code has to match the template configuring
# it.
@wulin_catalog = [
  {name: "wulin_master", branch: "v3-aida", required: true,
   summary: "grids, screens, menus, the esbuild/dart-sass pipeline"},
  {name: "wulin_permits",
   summary: "users, roles, privileges, per-screen permissions"},
  {name: "wulin_queue", needs: %w[wulin_permits],
   summary: "Solid Queue job screens: pending, failed, scheduled, processes"},
  {name: "wulin_audit",
   summary: "audit trail for every model write, plus request action logs"},
  {name: "wulin_excel",
   summary: "Excel export button on grid toolbars"}
]

# The component templates fill these in; this file assembles them at the end.
# All of them are written unindented -- wulin_indent puts them where they go.
@wulin_js = []           # paths to import from app/javascript/application.js
@wulin_sass = []         # indented-Sass rules for application.sass
@wulin_menus = []        # submenu blocks for ApplicationController.define_menu
@wulin_methods = []      # methods ApplicationController must define
@wulin_app_config = []   # YAML sections for config/app_config.yml
@wulin_post = []         # runs after bundle, before the database is set up
@wulin_db_post = []      # runs after db:migrate, for anything needing tables
@wulin_notes = []        # printed last, once everything has run

# A file shipping next to this template, read from disk or over HTTPS depending on how
# the template itself arrived.
def wulin_read(relative)
  path = "#{@wulin_source}/#{relative}"
  @wulin_remote_source ? URI.parse(path).open(&:read) : File.read(path)
end

# Asked of the remote rather than assumed -- the components do not agree on a name and
# are being renamed. Fatal on failure: a guessed branch vendors code that fails later.
def wulin_default_branch(url)
  symref = `git ls-remote --symref #{Shellwords.escape(url)} HEAD 2>/dev/null`
  symref[%r{^ref: refs/heads/(\S+)\s}, 1] or
    raise Thor::Error, "could not read the default branch of #{url} -- is it reachable?"
end

def wulin_vendor(name)
  component = @wulin_catalog.find { |c| c[:name] == name }
  url = "#{@wulin_git_base}/#{name}.git"
  # Written back so templates/README.md.erb reports what was vendored.
  branch = component[:branch] ||= wulin_default_branch(url)
  say_status :vendor, "#{name} (#{branch})", :green

  # rails new has not run git init yet at template time.
  run "git init -q" unless File.exist?(".git")

  # Idempotent, so a retry over a partial tree recovers. Guarded on the .gitmodules url
  # key, not the directory: a half-registered submodule has the directory but no mapping,
  # and skipping the re-add there leaves a .gitmodules that git rejects from then on.
  run <<~SH
    if ! git config -f .gitmodules --get submodule.vendor/gems/#{name}.url >/dev/null 2>&1; then
      git rm -f --cached vendor/gems/#{name} 2>/dev/null || true
      rm -rf vendor/gems/#{name} .git/modules/vendor/gems/#{name}
      git submodule add -q -b #{branch} #{url} vendor/gems/#{name}
    fi
    git config -f .gitmodules submodule.vendor/gems/#{name}.branch #{branch}
  SH

  gem name, path: "vendor/gems/#{name}"
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

def wulin_method(code)
  @wulin_methods << code
end

def wulin_post(&block)
  @wulin_post << block
end

def wulin_db_post(&block)
  @wulin_db_post << block
end

def wulin_note(text)
  @wulin_notes << text
end

def wulin_app_config(yaml)
  @wulin_app_config << yaml
end

def wulin_indent(blocks, spaces)
  blocks.map { |block|
    block.lines.map { |line| line.strip.empty? ? line : (" " * spaces) + line }.join
  }.join("\n")
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
    # successful build of an app missing four components.
    say_status :components, "stdin is not a tty and WULIN_COMPONENTS is unset -- installing only #{@wulin_catalog.select { |c| c[:required] }.map { |c| c[:name] }.join(", ")}", :yellow
    []
  end

  unknown = chosen - @wulin_catalog.map { |c| c[:name] }
  raise Thor::Error, "Unknown component: #{unknown.join(", ")}" if unknown.any?

  # A component's `needs` are code dependencies, not suggestions -- wulin_queue's
  # grids call current_user.has_permission_with_name? and its migration seeds
  # Permission rows, both of which come from wulin_permits.
  chosen.dup.each do |name|
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

create_file "config/app_config.yml", app_config
create_file "config/app_config.example.yml", app_config
append_to_file ".gitignore", "\n/config/app_config.yml\n"

after_bundle do
  # wulin_master:install writes its own ApplicationController with a stub menu,
  # so this has to come after it and replace the file wholesale.
  rails_command "generate wulin_master:install"

  file "app/javascript/application.js", <<~JS, force: true
    // wulin_master must be first: the other components attach to its globals
    // (WulinMaster.actions, gridManager, Ui, displayErrorMessage) at load time.
    #{@wulin_js.map { |path| "import \"#{path}\"" }.join("\n")}
  JS

  file "app/assets/stylesheets/application.sass",
    @wulin_sass.map(&:strip).join("\n\n") + "\n", force: true

  file "app/controllers/application_controller.rb", <<~RB, force: true
    # frozen_string_literal: true

    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

    #{wulin_indent(@wulin_methods, 2)}
      def self.define_menu
        menu do |c|
    #{wulin_indent(@wulin_menus, 6)}
        end
      end
    end
  RB

  @wulin_post.each(&:call)

  # Every engine appends its own db/migrate to the app's migration paths, so a
  # plain db:migrate picks all of them up -- nothing needs install:migrations.
  rails_command "db:create db:migrate"

  # Seeds the admin user every app needs, since current_user is User.first.
  rails_command "db:seed"

  @wulin_db_post.each(&:call)

  # README.md belongs to whoever created the repository -- on a Forge project it is
  # derived from the design. So the generated description always goes to
  # docs/wulin_app.md, and claims README.md only while it is still Rails' placeholder.
  doc = ERB.new(wulin_read("templates/README.md.erb"), trim_mode: "-").result(binding)
  file "docs/wulin_app.md", doc, force: true

  readme = File.exist?("README.md") ? File.read("README.md") : ""
  if readme.empty? || readme.include?("Things you may want to cover:")
    file "README.md", doc, force: true
  else
    wulin_note "README.md was left as it was -- what this template would have written is in docs/wulin_app.md"
  end

  say "\nWulin components installed: #{@wulin_install.map { |c| c[:name] }.join(", ")}", :green
  @wulin_notes.each { |note| say "  - #{note}", :yellow }
end
