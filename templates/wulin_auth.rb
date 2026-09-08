# wulin_auth -- session-based email+password authentication.
#
# Provides login/logout, current_user, require_login, password reset.
# Its User model has has_secure_password, so bcrypt is required.

wulin_vendor "wulin_auth", "rails8"

# wulin_auth injects current_user and require_login into
# ActionController::Base automatically via its engine. The template's
# stub current_user (User.first) is replaced by the real one.

wulin_post do
  # wulin_auth's migration creates users with email + password_digest +
  # token + token_expires_at. The admin column comes from wulin_permits
  # or wulin_master's own User generation — wulin_auth doesn't add it,
  # so we add it here if not already present.
  inject_into_file Dir.glob("db/migrate/*_create_users.rb").first,
    "      t.boolean :admin, default: false\n",
    after: "t.timestamps\n"

  append_to_file "db/seeds.rb", <<~RB
    User.find_or_create_by!(email: "admin@example.com") do |user|
      user.password = "password"
      user.admin = true
    end
  RB
end
