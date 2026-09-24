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

problems = []
upgrades = []
unreachable = []

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
    # vendors, so the two move together and a pin would only be a self-bump chore.
    next if ref.nil? && name == "wulin_master"

    if ref.nil?
      problems << "#{name}: no ref — apps get whatever #{branch} tips to on the day they are built"
      next
    end

    unless ref_fetchable?(name, ref, dir)
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
