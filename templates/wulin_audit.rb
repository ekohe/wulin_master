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

# lib/wulin_audit/extension.rb reads APP_CONFIG without a defined? guard, so an
# undefined constant means three logger.fatal lines on every create, update and
# destroy. wulin_master's template defines it in config/application.rb; this
# just documents the one key wulin_audit looks for.
wulin_app_config <<~YAML
  # wulin_audit only reads the influxdb key, and only if you set it.
  # wulin_audit:
  #   influxdb:
  #     host: localhost
  #     port: 8086
  #     database: audit
YAML

wulin_note "wulin_audit: every model is audited by default -- use reject_audit in a model to opt out"
wulin_note "wulin_audit: the record_audit#read permission is not created for you; add it if you use wulin_permits"
