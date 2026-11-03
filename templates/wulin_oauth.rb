# wulin_oauth -- sign-in through the OAuth provider (mima), the alternative to wulin_auth.
#
# The users are the provider's: User is the gem's own ActiveModel class, filled from the provider's
# JSON, and nothing about them is stored in this app's database. The gem's controller mixin, included
# into ActionController::Base, defines current_user, require_login and require_admin, and its
# routes (/login, /logout, /oauth/callback, resources :users) are drawn into the app directly.
#
# The gem ships no login-page assets; both are built below.

wulin_vendor "wulin_oauth"

# The gem never sets the thread-local User.current_user, and wulin_audit reads it in process_action.
# So every request writes it first -- including those require_login redirects, which halt the chain
# before any later filter. The login actions skip require_login.
wulin_filter "before_action :set_current_user\nbefore_action :require_login"
wulin_method <<~RB
  def set_current_user
    User.set_current_user(current_user)
  end
RB

# The user-management actions (invite, create, remove, reset) register with WulinMaster in the main
# bundle. Each file checks for WulinMaster first, which is what lets the login bundle below import the
# same entry without it.
wulin_js "../../vendor/gems/wulin_oauth/app/javascript/wulin_oauth.esm.js"

# The login page's bundle. Its views call $(document).ready inline, so jQuery is published first.
file "app/javascript/wulin_oauth.js", <<~JS, force: true
  // The login page's own bundle -- layouts/session.html.haml loads it instead of application.js.
  // Written by the wulin template and rewritten when it is re-applied.
  import "../../vendor/gems/wulin_master/app/assets/javascripts/master/jquery_setup.js"
  import "../../vendor/gems/wulin_oauth/app/javascript/wulin_oauth.esm.js"
JS
wulin_entry "app/javascript/wulin_oauth.js"

# The login page's stylesheet. _materialize_themed is the one master.sass builds on, so the login page
# wears the app's color_theme.
file "app/assets/stylesheets/wulin_oauth.sass", <<~SASS, force: true
  // The login page's stylesheet (layouts/session.html.haml), built apart from application.css.
  // Written by the wulin template and rewritten when it is re-applied.
  @use "materialize-css/sass/components/color-variables" as materialize_color
  @use "materialize_themed"

  html
    height: 100%

  body
    height: 100%
    background: materialize_color.color("grey", "lighten-4")

  #container
    height: 100%
SASS

# Written once; after that both are the app's.
unless File.exist?("config/wulin_oauth.example.yml")
  file "config/wulin_oauth.example.yml", <<~YAML
    # wulin_oauth's client settings. Copy to config/wulin_oauth.yml (gitignored) and fill in the
    # oauth_identifier and oauth_secret the provider issued for development and production -- never
    # here. test's are placeholders, for specs that never reach the provider.
    provider: &provider
      authorize_uri: https://mima.ekohe.com/oauth/authorize
      access_token_uri: https://mima.ekohe.com/oauth/access_token
      resource_host: https://mima.ekohe.com
      change_password_uri: https://mima.ekohe.com/users/change_password
      logout_uri: https://mima.ekohe.com/logout

    development:
      <<: *provider
      redirect_uri: http://localhost:3000/oauth/callback
      oauth_identifier: ""
      oauth_secret: ""

    test:
      <<: *provider
      redirect_uri: http://localhost:3000/oauth/callback
      oauth_identifier: test
      oauth_secret: test

    production:
      <<: *provider
      redirect_uri: https://your-app.example.com/oauth/callback
      oauth_identifier: ""
      oauth_secret: ""
  YAML
end
run "cp config/wulin_oauth.example.yml config/wulin_oauth.yml" unless File.exist?("config/wulin_oauth.yml")
unless File.read(".gitignore").include?("/config/wulin_oauth.yml")
  append_to_file ".gitignore", "\n/config/wulin_oauth.yml\n"
end

wulin_post do
  unless wulin_written?("config/initializers/wulin_master_assets.rb", "wulin_oauth.sass")
    inject_into_file "config/initializers/wulin_master_assets.rb",
      after: '  config.dartsass.builds = {"application.sass" => "application.css"}' + "\n" do
      <<~RB
        config.dartsass.builds["wulin_oauth.sass"] = "wulin_oauth.css"
      RB
    end
  end
end

wulin_note "wulin_oauth: sign-in needs the client id and secret the provider issued -- fill them into config/wulin_oauth.yml (gitignored; config/wulin_oauth.example.yml is the committed copy)"
wulin_note "wulin_oauth: AddUserScreen (\"Invite User\") is not on the menu -- it is gated by WulinPermits::UserManagement::INVITE; add it where your users are managed"
wulin_note "wulin_oauth: it and wulin_permits both draw `resources :users`, and it extends wulin_permits' UsersController -- keep host routes off /users"
