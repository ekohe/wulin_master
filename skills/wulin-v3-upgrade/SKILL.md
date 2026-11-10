---
name: wulin-v3-upgrade
description: Move an existing wulin app (submodule or path components, hand-wired assets) onto the wulin_master v3 template, so later upgrades are a template re-apply. Use when asked to upgrade a project to wulin_master v3 / the v3 template, or to re-apply the template to an app that was not made by it.
---

# Upgrade an app to the wulin_master v3 template

The goal is not "an app that runs on v3" but "an app the v3 template owns the wiring of": after
this, a wulin upgrade is `bin/rails app:template` plus a diff review.

An app that has no `wulin_permits`, no `wulin_oauth`, no Capistrano, no GitLab CI, and no
`config/server` tree still upgrades. Those show up below only as checks the preflight runs when
it finds them. Skipping a check the app has nothing for does not leave the upgrade unfinished.
What one app kept, and why, is not part of this procedure.

Work on a branch, commit per step with the repo's commit conventions, never push. Stop and ask
when a step needs a product decision (menu layout, auth provider, deploy changes) -- or, in an
unattended run, follow "Unattended runs" below.

This skill ships inside wulin_master, next to the `template.rb` and `components.lock.yml` it applies,
so the checkout it is read from is `WM`: the procedure and the template are always the same commit.
`scripts/` next to this file is the skill's, not the app's. Run the scripts by that path.

## Inputs

- `WM`: the wulin_master checkout this skill was read from (`<skill>/../..`), at the `v3` tip.
- The app's component list, in the template's names (`wulin_auth` or `wulin_oauth`, never both).
  `wulin_oauth` needs `WULIN_COMPONENTS` to name it explicitly: `all` means wulin_auth.
- `WULIN_DOCKER=0` unless the app wants the template's container stack.

Apps from the previous wulin generation share a layout: component submodules, Capistrano, and a
`config/server/<stage>/` tree. The directory under the stage is not one path -- some apps use
`config/`, others `shared/config/`. Preflight lists every `config/**/app_config*.yml`; that list
is the one to update. An encrypted copy (`app_config.yml.enc`) is edited only by whoever holds its
key: name it, with the values its `wulin_master:` key needs, for them. The usual suite
(`wulin_oauth`, `wulin_permits`, `wulin_queue`, `wulin_audit`, `wulin_excel`) is that generation's
component set, passed as `WULIN_COMPONENTS`.

## 0. Preflight (read-only)

```bash
ruby <skill>/scripts/preflight.rb <app>
```

Then run the app's tests (AGENTS.md / README) for a baseline. Gate before going on:

- Ruby >= 3.4 and Rails >= 8.1. Below that, upgrade Ruby/Rails first, as its own branch: the
  template and the gemspecs refuse older ones. Stay on the newest Ruby the app already deploys;
  do not bump to a newer major as part of this upgrade.
- "LOCK WOULD DROP n COMMIT(S)" on any component: stop. The component's maintainer merges that
  work into the release branch (main; v3 for wulin_master/wulin_oauth) and bumps the lock first.
  The comparison uses a local checkout when there is one (`vendor/gems`, a `.gitmodules` path, or
  a Gemfile `path:`), and otherwise the revision in `Gemfile.lock`. A lockfile mismatch with no
  checkout cannot count commits -- fetch the checkout before treating it as safe.
- Sprockets, `.coffee`, `//= require`, `image-url`: the app is not on esbuild/dart-sass yet --
  that conversion comes before this skill.
- Overridden gem files and reopened `Wulin*` classes: list them for the user; they survive the
  template but may break silently against newer component code. After step 1, check each one
  against the locked gem: a file it `require_dependency`s or reopens must still exist there, or the
  override goes -- it otherwise fails at load, or shadows the gem's newer class.

## 1. Switch the components to Bundler git gems

Skip this step when the Gemfile already declares each `wulin_*` gem the way the template writes
it.

1. Rewrite each `gem "wulin_*"` line to the lock's source, exactly as the template writes it:
   `gem "wulin_master", github: "ekohe/wulin_master", branch: "v3"`; pinned components get
   `github: "ekohe/<name>", ref: "<full sha>"` (no branch -- Bundler cannot find a ref behind a
   moved branch tip).
2. When `.gitmodules` lists the components: confirm every checkout is clean and its HEAD is on a
   remote branch, then `git rm` the submodules of the components the template installs. Preflight
   names the others -- an app-owned gem such as `wulin_wiki`, or a repository that is not a gem.
   They stay submodules, with their `.gitmodules` entries and `path:` lines; `.gitmodules` goes
   only when nothing is left in it. Do not delete `.git/modules`. An app with no submodules has
   nothing to remove here.
3. `bundle install`. Check the GitHub mirror is current: the lock's wulin_master revision must
   equal `git ls-remote https://github.com/ekohe/wulin_master.git refs/heads/v3`.
4. `.gitignore`: add `/vendor/gems` and `/.env*` (the template adds them only to new apps). Drop
   any ignore of `app/assets/fonts` or `_theme.generated.scss`: the template writes those once and
   they are committed -- the app task that regenerated them at deploy goes in step 2.

## 2. Adopt the template's structure (what it refuses or silently misses)

Every item here is something the preflight flags; fix only what it flags.

- **ApplicationController**: `include WulinComponents`; remove the components' filters and
  methods (the concern defines them -- e.g. `set_current_user` must run before `require_login`
  when both exist); remove the components' screens from the app's menu and call
  `wulin_component_menus` inside `menu do`. Groups with the same title are not merged, so an app
  item that belongs with a component group (another Access Control screen) moves to one of the
  app's groups. Keep `AppConfigsScreen` where the app has it: the template adds its own "Settings"
  group only when the controller does not name that screen. Without `wulin_permits` the template
  leaves `AppConfigsScreen` off the menu and says so.
- **Placeholder concern**: `rails app:template` boots the app, so create
  `app/controllers/concerns/wulin_components.rb` with an empty `WulinComponents` concern
  defining an empty `wulin_component_menus` inside `class_methods do` (`define_menu` calls it on
  the class); the template overwrites it.
- **Entries**: `app/javascript/application.js` keeps only the app's imports (the template
  prepends `import "./wulin_components"`). App styles go to a partial used from
  `app/assets/stylesheets/application.sass`; drop rules the installed components' templates
  already emit. They now load after the components' styles, so an app rule wins a tie it used to
  lose -- tell the reviewer.
- **Files the template writes only when missing** -- delete the app's copy so it writes its own:
  `config/initializers/wulin_master_assets.rb` (components inject after its builds line),
  `config/initializers/wulin_master.rb` (after moving its values to the `wulin_master:` key of
  `config/app_config.example.yml` and every other `app_config*.yml` the preflight listed; the
  values the old initializer took effect with replace a `wulin_master:` key it ignored, and a value
  read from the database goes back into the written initializer, which is the app's from then on),
  `script/copy_material_icons.js`, a component entry the template rewrites (`wulin_oauth.js` or
  `wulin_auth.js`, only the one this app has), and app-made build tasks
  (e.g. `lib/tasks/wulin_assets.rake`).
- **Anchors**: `config/environments/*.rb` open with `Rails.application.configure do`;
  `bin/setup` is Rails 8.1's (`system("bundle check") || system!("bundle install")`);
  `config/application.rb` has no APP_CONFIG block of its own.
- **Lint**: if `.standard.yml` sets `default_ignores: false`, add `node_modules/**/*` -- the npm
  workspace `node_modules/wulin_master` links into the installed gem, and `standard:fix` would
  rewrite it. (If that already happened: `git -C <gem path> checkout -- .`.)
- **database.yml**: on macOS with libpq 18, add `gssencmode: disable` under development, in the
  committed example too. The template warns about this because Solid Queue's forked workers
  segfault on their first query. Other platforms skip it.

## 3. Apply the template

```bash
WULIN_COMPONENTS=<list> WULIN_DOCKER=0 bin/rails app:template LOCATION=<WM>/template.rb < /dev/null
```

Apply it again until `git status` shows nothing new -- the second run should change nothing.
Expect the template to: remove `web-console`/`debug`/... from the Gemfile (the list is whatever
this `template.rb` removes; preflight reads it); add `json < 3.0`, `jsbundling-rails`,
`foreman`; replace yarn with npm (`package-lock.json`); write `.env.example`, `docs/wulin_app.md`,
the AGENTS.md block, the fonts and `_theme.generated.scss` (committed); run migrations and
`db:seed` on the development database.

Check after every apply:

- `Gemfile.lock`'s wulin_master revision equals
  `git ls-remote https://github.com/ekohe/wulin_master.git refs/heads/v3`. A re-apply moves it there
  itself; a difference means the mirror moved during the run -- apply again.
- A component declared with `path:` is left alone on purpose (the run says so) -- if that is a
  leftover from editing the gem, switch it back to the pin.
- The gems the template appended (`json`, `jsbundling-rails`, `foreman`) may be moved into the
  app's own grouping; keep each line's arguments (`group: :development` on foreman), or every
  re-apply notes the declaration as lacking them.
- A component builds line injected into `wulin_master_assets.rb` (`wulin_oauth.sass` or
  `wulin_auth.sass`) is indented. The template injects it unindented; fix the indent once -- it is
  not injected again.
- Where the template appended a `.gitignore` line the app already had (in another spelling), keep
  the template's and drop the app's, so a re-apply finds its own line and adds nothing.

## 4. Review the diff

Accept the template-owned files. For the shared ones (Gemfile, package.json, .gitignore,
app_config, AGENTS.md, config/application.rb) check only that the app's own lines survived.
List for the reviewer the app files step 2 rewrote rather than the template: the
`config/environments/*.rb` openers and `bin/setup`.
Report the menu change to the user. The groups that appear are the ones for components this app
installed (Access Control, Background Jobs, Audit, Assistant, Settings) -- it is their call
whether the app keeps an extra item.

## 5. CI and deploy

Do this only for the CI and the deploy tool the preflight found. An app with neither is done
after the template apply and the verify step.

- CI: drop yarn steps, and the submodule steps once no submodule is left; after `bundle install` run
  `bundle exec ruby script/link_wulin_gems.rb`; build before specs:
  `bin/rails javascript:build dartsass:build`.
- Capistrano: when `Capfile` uses a submodule strategy and no submodule is left, remove
  `capistrano-git-with-submodules` (Capfile and Gemfile). Either way, add a task running
  `bundle exec ruby script/link_wulin_gems.rb` after `bundler:install`. `assets:precompile` then
  runs `npm install` + esbuild via jsbundling-rails; the server needs node/npm on PATH and HTTPS
  access to github.com. Verify with `cap <stage> deploy --dry-run`.
- README: setup is copy configs, then `bin/setup`; run with `bin/dev`.

## 6. Verify (all must pass before committing)

- The app's own AGENTS.md / README checks, whichever commands that app documents.
- `bin/rails javascript:build dartsass:build` and
  `RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile`.
- `bin/setup --skip-server`, then `bin/dev`: `/login` (or `/`, for an app with no auth gem) and
  its assets return 200, no worker segfault in the log.
- Menu smoke, when the app has `wulin_auth` or `wulin_oauth`:
  `bin/rails runner <skill>/scripts/menu_smoke.rb`. It stubs `current_user` (oauth via
  `User.from_session`'s attributes, auth via an unsaved `User`), then requests each `#menu` screen
  as the browser does, layout then `xhr=1`. A link alone returns 200 even when the screen's table
  or view is missing. The default run then signs in as a member with no permission rows. With
  `wulin_permits`, each screen that left that menu must answer 401 or 403. Without it, the
  two menus match. The script exits non-zero on a failure. `LEVEL=administrator` or `LEVEL=member`
  runs one pass.
- When the app uses `wulin_permits`: `db/schema.rb` holds `create_view "user_all_permissions"` and
  `"permission_all_users"` (dumped by scenic) -- otherwise every database built from schema.rb
  fails on Permissions / Users. The lock's wulin_permits carries RecreatePermissionViews, which
  restores them on `db:migrate`; commit the schema dumped from a database built by `db:migrate`
  alone. Anything else in its diff is a stale dump catching up -- say so in the commit. An app
  without that gem has neither view; do not add them.
- Reproduce the CI job in the CI image with `CI=true`, when the app has one. Leave out only the
  steps that need the CI runner's secrets (an `ssh-add` of its deploy key), and say so.
- Add a request spec for what the move changes (filter order, login bundle) when the app's
  definition of done requires a spec for the change. A spec that renders a page needs the assets
  built first.

## 7. Leftovers and commit order

Remove only what is proven unused, each with its evidence in the commit message:
- Sprockets/Webpacker remnants: `terser` (only a `js_compressor` used it), comment-only
  initializers such as `config/initializers/assets.rb`, `public/packs` in Capistrano's
  `linked_dirs` when Capistrano is in use.
- On Ruby 4.0, `ostruct` left the default gems. Drop `gem "ostruct"` once
  `BUNDLE_WITHOUT="development:test" RAILS_ENV=production bin/rails runner 'Rails.application.eager_load!'`
  boots without it, unless another dependency (sshkit, for one) needs it in that environment.
- Keep a setting that has a stated reason, and put that reason in the commit message. Keep what
  you cannot prove unused, and say so.

Commits, each one passing the checks above on its own: preparation (lint config, dead config) →
the adoption, already at the lock's current refs, with step 5 in it (CI and deploy fail on a
commit that has removed the submodules without them) → dependency/security bumps (re-apply so the
AGENTS.md block names them) → specs → leftover removals. Fold fixes found later into the commit
they belong to rather than adding "fix the adoption" commits.

## Unattended runs

When a runner (AIDA, CI) drives this skill with nobody to ask, the procedure is the same; what
changes is who decides and who publishes.

- The runner provides: the app checked out on a fresh branch from its base branch, `WM`, the
  Ruby the app deploys on (its `.ruby-version`, else its CI image or deploy config), the app's
  gitignored configs copied from their examples, a reachable PostgreSQL, and `WULIN_COMPONENTS`
  (derived from the app's Gemfile when not given). Keep the example's database names: the
  template names the app after the development database in `config/database.yml`, and writes
  that name into AGENTS.md, `docs/wulin_app.md` and the initializer. Isolate runs by PostgreSQL
  instance, not by renaming databases.
- A gate in step 0 (Ruby/Rails floor, "LOCK WOULD DROP", Sprockets) ends the run: commit nothing,
  report the gate. These are not this skill's to work around.
- Every "stop and ask" takes the default this file states (keep the app's menu groups, keep the
  auth gem the app has, change deploy only as step 5 describes) and lists it under decisions in
  the report, for the reviewer.
- Commit as described; never push. Pushing the branch and opening the merge request is the
  runner's job, with the report as its description.
- End with the report: the gates and their result; the commits; each decision taken by default;
  each check in step 6 with pass/fail and the command that ran it; what step 7 kept and why.

## Hand-off notes for the commit message

When the components were submodules, existing checkouts must `git submodule deinit -f` each
removed component's path before pulling (`--all` when no submodule is left), or delete those
leftover `vendor/gems/wulin_*` directories -- `link_wulin_gems.rb` refuses real directories -- then
`bin/setup`. Name any component migrations the bump brings in.
