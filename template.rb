# rails new wulin_app --skip-hotwire --database=postgresql -j esbuild -m ./template.rb
#
# Asks which Wulin components you want, then vendors and configures each one.
# Set WULIN_COMPONENTS to skip the questions:
#
#   WULIN_COMPONENTS=all rails new ... -m ./template.rb
#   WULIN_COMPONENTS=wulin_audit,wulin_excel rails new ... -m ./template.rb
#
# Rails 8 adds solid_queue/solid_cache/solid_cable by default. wulin_queue
# owns the Solid Queue schema in the primary database, so strip the duplicate.
gsub_file "Gemfile", /^gem "solid_queue"\n/, ""
gsub_file "Gemfile", /^gem "solid_cache"\n/, ""
gsub_file "Gemfile", /^gem "solid_cable"\n/, ""

# Remove gems we don't use.
%w[debug rubocop-rails-omakase web-console capybara selenium-webdriver tzinfo-data].each do |name|
  gsub_file "Gemfile", /^.*gem "#{name}".*\n/, ""
end

# Strip empty group blocks left behind after removing gems.
gsub_file "Gemfile", /^group :[^\n]+\n(#[^\n]*\n|\s*\n)*end\n/, ""

gem_group :development, :test do
  gem "standard"
end

# The develop branches are identical on both hosts, so everything comes
# from one place.
@wulin_git_base = "git@gitlab.ekohe.com:ekohe/wulin"
@wulin_templates = File.expand_path("templates", __dir__)

# Order here is install order, and it matters: wulin_permits must land before
# wulin_queue so the Permission model exists when the queue migrations seed it.
@wulin_catalog = [
  {name: "wulin_master", branch: "v3", required: true,
   summary: "grids, screens, menus, the esbuild/dart-sass pipeline"},
  {name: "wulin_auth", branch: "rails8", required: true,
   summary: "login/logout, current_user, password reset"},
  {name: "wulin_permits", branch: "develop",
   summary: "users, roles, privileges, per-screen permissions"},
  {name: "wulin_queue", branch: "develop", needs: %w[wulin_permits],
   summary: "Solid Queue job screens: pending, failed, scheduled, processes"},
  {name: "wulin_audit", branch: "develop",
   summary: "audit trail for every model write, plus request action logs"},
  {name: "wulin_excel", branch: "develop",
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

def wulin_vendor(name, branch)
  # rails new has not run git init yet at template time.
  run "git init -q" unless File.exist?(".git")
  run "git submodule add -q -b #{branch} #{@wulin_git_base}/#{name}.git vendor/gems/#{name}"
  run "git config -f .gitmodules submodule.vendor/gems/#{name}.branch #{branch}"
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
  elsif requested.empty?
    optional.select { |c| yes?("Install #{c[:name]}? (#{c[:summary]}) [y/N]") }.map { |c| c[:name] }
  else
    requested.split(",").map(&:strip).reject(&:empty?)
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
  say_status :component, "#{component[:name]} (#{component[:branch]})", :green
  path = File.join(@wulin_templates, "#{component[:name]}.rb")
  instance_eval(File.read(path), path)
end

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

  # Rails ships a placeholder checklist. Render templates/README.md.erb instead,
  # which describes the app that actually got built.
  readme = File.join(@wulin_templates, "README.md.erb")
  file "README.md", ERB.new(File.read(readme), trim_mode: "-").result(binding), force: true

  say "\nWulin components installed: #{@wulin_install.map { |c| c[:name] }.join(", ")}", :green
  @wulin_notes.each { |note| say "  - #{note}", :yellow }
end
