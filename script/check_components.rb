#!/usr/bin/env ruby
# frozen_string_literal: true

# Will a scaffold still work as pinned, and has anything newer landed?
#
#   ruby script/check_components.rb           # report
#   ruby script/check_components.rb --bump    # move the refs to the current branch tips
#
# `components.lock.yml` pins a COMMIT per component, so a generated app is reproducible and this is
# not a drift alarm: a branch that moved ahead is an upgrade somebody may take, not a fault. What it
# does treat as a fault is anything that makes a scaffold fail or be unrepeatable — a pinned commit
# that is no longer fetchable, a tracked branch that is gone, a component nobody pinned.
#
# The pin is checked the way the scaffold uses it: `git fetch --depth 1 <url> <sha>` is the same
# call `wulin_vendor` makes. That is the only thing proving a scaffold will work, and a force-push
# orphaning a pinned commit is invisible to anything that only lists branches.
#
# Exit status is the whole interface: 0 when every scaffold will work, 1 when one will not.

require "yaml"
require "shellwords"
require "tmpdir"

ROOT = File.expand_path("..", __dir__)
LOCK = File.join(ROOT, "components.lock.yml")
GIT_BASE = "https://github.com/ekohe"

bump = ARGV.include?("--bump")
write_inventory = ARGV.include?("--inventory")
INVENTORY = File.join(ROOT, "components.inventory.yml")
lock_source = File.read(LOCK)
pins = YAML.safe_load(lock_source).fetch("components")

# The catalog names the components; the lock resolves them. Neither is allowed to know about a
# component the other does not, or a scaffold fails on a name nothing pins — or carries a pin for
# something it never vendors, which is dead data that reads as coverage.
catalog = File.read(File.join(ROOT, "template.rb")).scan(/\{name: "([^"]+)"/).flatten

def remote_tip(name, branch)
  url = "#{GIT_BASE}/#{name}.git"
  out = `git ls-remote #{Shellwords.escape(url)} #{Shellwords.escape("refs/heads/#{branch}")} 2>/dev/null`
  # A branch that is gone exits 0 with empty output; a remote that could not be reached exits 128.
  # Collapsing them turns somebody else's outage into a red build blaming a branch that is fine.
  return [:unreachable, nil] unless $?.success?

  sha = out[/\A(\h{40})/, 1]
  sha ? [:ok, sha] : [:gone, nil]
end

def ref_fetchable?(name, ref, dir)
  system("git", "-C", dir, "fetch", "-q", "--depth", "1", "#{GIT_BASE}/#{name}.git", ref,
    out: File::NULL, err: File::NULL)
end

# What a component CONTRIBUTES, read off the ref that was just fetched. Three file-existence facts,
# nothing about what any of it means:
#
#   screens     the pages that belong in a menu group, as class names
#   esm         the esbuild entry an app has to import, if it ships one
#   migrations  how many it appends, so `db:migrate` doing nothing is visibly wrong
#
# Derived, never written. The prose enumeration this replaces rotted into claiming a gem that does
# not exist and attributing one gem's method to another; `git ls-tree` can do neither. It is also the
# answer to the question that cost one build ten minutes -- which screens does a capability bring --
# and which no amount of reading the app could give, because the answer is in the gem.
#
# `ls-tree` on FETCH_HEAD rather than a checkout: the objects are already here from the fetch above,
# and a checkout of six components per run is the slow way to read a file list.
def inventory_at(dir, treeish)
  out = `git -C #{Shellwords.escape(dir)} ls-tree -r --name-only #{Shellwords.escape(treeish)} 2>/dev/null`
  return nil unless $?.success?

  paths = out.lines(chomp: true)
  {
    "screens" => paths.grep(%r{\Aapp/screens/.+\.rb\z})
      .map { |f| File.basename(f, ".rb").split("_").map(&:capitalize).join }.sort,
    "esm" => paths.grep(%r{\Aapp/javascript/.+\.esm\.js\z}).map { |f| File.basename(f) }.sort,
    "migrations" => paths.count { |f| f.start_with?("db/migrate/") && f.end_with?(".rb") },
    "editors" => editors_at(dir, treeish, paths)
  }.compact
end

# The cell editors a component registers, by name. Derived for the same reason as the rest, and
# added because naming one that does not exist is the worst failure this catalogue can prevent:
# SlickGrid raises while building the column, so the page loads, the toolbar renders, the JSON
# endpoint answers 200 -- and the grid is simply absent, with nothing in the server log.
#
# `git show` per file rather than a checkout: only wulin_master defines any, so this reads one blob.
def editors_at(dir, treeish, paths)
  files = paths.grep(%r{\Aapp/assets/javascripts/.*editors\.js\z})
  return nil if files.empty?

  names = files.flat_map { |f|
    blob = `git -C #{Shellwords.escape(dir)} show #{Shellwords.escape("#{treeish}:#{f}")} 2>/dev/null`
    $?.success? ? blob.scan(/^\s*this\.([A-Z][A-Za-z0-9]*Editor)\s*=\s*function/).flatten : []
  }
  names.empty? ? nil : names.uniq.sort
end

# The editor names a component's README TEACHES, which is a different question from the ones it
# registers. A README outlives the code it documents, and the conventions pack AIDA gives its agents
# sends them here and calls it authoritative for the gem's API -- so a name it keeps after the class
# is gone is copied into a generated app verbatim.
#
# Checked against the union of every component's editors rather than its own, because a README may
# reasonably name an editor another gem in the suite registers.
def readme_editors_at(dir, treeish)
  blob = `git -C #{Shellwords.escape(dir)} show #{Shellwords.escape("#{treeish}:README.md")} 2>/dev/null`
  return [] unless $?.success?

  blob.scan(/\b([A-Z][A-Za-z0-9]*Editor)\b/).flatten.uniq.sort
end

problems = []
upgrades = []
unreachable = []
inventory = {}
readme_editors = {}

(pins.keys - catalog).each { |name| problems << "#{name}: pinned here but template.rb's catalog does not name it" }
(catalog - pins.keys).each { |name| problems << "#{name}: in template.rb's catalog with nothing pinning it" }

Dir.mktmpdir do |dir|
  system("git", "-C", dir, "init", "-q", out: File::NULL, err: File::NULL)

  pins.each do |name, pin|
    branch = pin.fetch("branch")
    # `.to_s` because YAML types a scalar, and a sha that happens to be all digits parses as an
    # Integer -- which `system` refuses outright and `ref[0, 8]` silently bit-slices. Unlikely, and
    # the failure is a stack trace rather than an answer, which is the wrong way round for a check.
    ref = pin["ref"]&.to_s

    # wulin_master is this repository: the template is served from the same branch as the gem it
    # vendors, so the two move together and a pin would only be a self-bump chore. Its inventory is
    # read from HEAD here for the same reason — there is no other copy to fetch.
    if ref.nil? && name == "wulin_master"
      if (facts = inventory_at(ROOT, "HEAD"))
        inventory[name] = facts
      end
      readme_editors[name] = readme_editors_at(ROOT, "HEAD")
      next
    end

    if ref.nil?
      problems << "#{name}: no ref — apps get whatever #{branch} tips to on the day they are built"
      next
    end

    if ref_fetchable?(name, ref, dir)
      # Only from a ref that fetched: an inventory read off anything else is a claim about code
      # nobody can get.
      if (facts = inventory_at(dir, "FETCH_HEAD"))
        inventory[name] = facts
      end
      readme_editors[name] = readme_editors_at(dir, "FETCH_HEAD")
    else
      problems << "#{name}: pinned at #{ref[0, 8]}, which the remote will not serve — every " \
                  "scaffold fails here (force-push?)"
    end

    status, tip = remote_tip(name, branch)
    case status
    when :unreachable then unreachable << "#{name} (#{branch})"
    when :gone then problems << "#{name}: the tracked branch #{branch} no longer exists"
    else upgrades << [name, branch, ref, tip] if tip != ref
    end
  end
end

# A name a README teaches must be a name some component registers. Skipped when nothing fetched an
# editor at all, because then the union is empty for a reason that has nothing to do with the READMEs
# and every mention would be reported.
known_editors = inventory.values.flat_map { |f| f["editors"] || [] }.uniq
if known_editors.any?
  readme_editors.each do |name, taught|
    (taught - known_editors).each do |bogus|
      problems << "#{name}: README.md teaches `#{bogus}`, which no component registers — an app " \
                  "that copies the example renders no grid at all, silently"
    end
  end
end

# The inventory is DERIVED, so it is written by a flag and verified by every other run. A generated
# file nobody checks is a generated file that goes stale the first time somebody bumps a ref and
# forgets — which is exactly how the prose enumeration this replaces became wrong.
if write_inventory
  File.write(INVENTORY, <<~HEAD + YAML.dump(inventory).sub(/\A---\n/, ""))
    # DERIVED — do not edit. Regenerate with `ruby script/check_components.rb --inventory`.
    #
    # What each component contributes, read off the commit `components.lock.yml` pins it at. Three
    # file-existence facts and nothing else: the screens that belong in a menu group, the esbuild
    # entry an app must import, and how many migrations it appends.
    #
    # It exists so that nobody — person or agent — has to read a gem's source to find out what
    # installing it puts in front of a user. The prose version of this rotted into naming a gem that
    # does not exist; `git ls-tree` cannot.
    #
    # Every run of check_components.rb verifies this file is current, so a bumped ref that did not
    # regenerate it fails rather than lying.
  HEAD
  puts "wrote #{File.basename(INVENTORY)} for #{inventory.size} component(s)"
  exit 0
end

if inventory.any? && File.exist?(INVENTORY)
  recorded = YAML.safe_load_file(INVENTORY) || {}
  stale = inventory.reject { |name, facts| recorded[name] == facts }
  stale.each_key { |name| problems << "#{name}: components.inventory.yml is stale — re-run with --inventory" }
elsif inventory.any?
  problems << "components.inventory.yml is missing — run `ruby script/check_components.rb --inventory`"
end

if bump
  if upgrades.empty?
    puts "nothing to bump"
    exit 0
  end
  # Substituted rather than re-serialised: YAML.dump would drop every comment in the file, and what
  # the file is FOR is largely in them. A ref line is `ref: <40 hex>`, which is unambiguous.
  upgrades.each do |name, _branch, ref, tip|
    lock_source = lock_source.sub(/(^\s*#{Regexp.escape(name)}:\n(?:.*\n)*?\s*ref: )#{ref}$/, "\\1#{tip}")
    puts "#{name}: #{ref[0, 8]} → #{tip[0, 8]}"
  end
  File.write(LOCK, lock_source)
  warn "\nRefs rewritten and NOT verified: re-run the scaffold named in `verified_by`, and commit " \
       "its result together with this change."
  exit 0
end

unreachable.each { |what| warn "? #{what}: remote unreachable, not checked" }
upgrades.each do |name, branch, ref, tip|
  puts "↑ #{name}: #{branch} is at #{tip[0, 8]}, pinned at #{ref[0, 8]} — an upgrade is available"
end

if problems.empty?
  pinned = pins.count { |_, pin| pin["ref"] }
  # Built as nils rather than ternaries inside the interpolation: nil renders as nothing, and the
  # line stays one sentence instead of three fragments joined by conditionals.
  newer = ", #{upgrades.size} with something newer" if upgrades.any?
  unchecked = ", #{unreachable.size} unchecked" if unreachable.any?
  puts "✓ #{pinned} pinned component(s) fetchable#{newer}#{unchecked} " \
       "(verified #{YAML.safe_load(lock_source)["verified_at"]})"
  exit 0
end

warn "\nA scaffold would not work as pinned:"
problems.each { |p| warn "  - #{p}" }
warn <<~NEXT

  A pin that cannot be fetched is not an upgrade decision — it breaks every new app until the lock
  names a commit that exists.

  If you are changing which BRANCH a component is tracked on, Forge's capability catalog
  (config/wulin_capabilities.yml, Platform::Catalog::DEFAULT_BRANCH) names branches for the same
  gems on the evolve-build path. Change both, or the same capability follows different lines
  depending on whether it was selected at creation or added later.
NEXT
exit 1
