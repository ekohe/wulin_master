# wulin_audit -- records every ActiveRecord write, plus a log of each request.
#
# Despite what the old docs claimed, this no longer needs MongoDB: the models
# are plain ActiveRecord. It does need PostgreSQL, because the audit tables use
# jsonb columns.

wulin_vendor "wulin_audit", "develop"

# The gem does `require "haml-rails"` at load but only lists it as a development
# dependency, so without this the app raises LoadError on boot.
gem "haml-rails"

# app/assets/javascripts/audit.js is just a Sprockets manifest; this is the file
# it points at.
wulin_js "../../vendor/gems/wulin_audit/app/assets/javascripts/actions/show_audit_logs.js"

# The gem's audit.css.scss uses image-url(), a sass-rails function dart-sass
# does not have, so the one rule in it is reproduced here. Propshaft indexes the
# engine's app/assets/images, so the bare filename resolves.
wulin_sass <<~SASS
  .toolbar_icon_audit
    background: url("audit.png") no-repeat top center
SASS

wulin_menu <<~RB
  submenu "Audit" do
    item AuditLogScreen, icon: :history
    item ActionLogScreen, icon: :assignment
  end
RB

# lib/wulin_audit/extension.rb reads APP_CONFIG without a defined? guard. The
# surrounding rescue keeps the audit itself intact, but an undefined constant
# means three logger.fatal lines on every single create, update and destroy.
initializer "app_config.rb", <<~RB
  # frozen_string_literal: true

  # wulin_audit expects this to exist. Real apps load it from a YAML file; the
  # only key it looks for is APP_CONFIG["wulin_audit"]["influxdb"].
  APP_CONFIG = {}
RB

wulin_note "wulin_audit: every model is audited by default -- use reject_audit in a model to opt out"
wulin_note "wulin_audit: the record_audit#read permission is not created for you; add it if you use wulin_permits"
