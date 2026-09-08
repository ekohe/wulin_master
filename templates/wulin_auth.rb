# wulin_auth -- session-based email+password authentication.
#
# Provides login/logout, current_user, require_login, password reset.
# Its User model has has_secure_password, so bcrypt is required.

wulin_vendor "wulin_auth", "rails8"

# wulin_auth injects current_user and require_login into
# ActionController::Base automatically via its engine. The template's
# stub current_user (User.first) is replaced by the real one.

wulin_post do
  # wulin_auth's migration lives in the engine. Add the admin column
  # via a separate app-level migration.
  generate :migration, "AddAdminToUsers admin:boolean"

  append_to_file "db/seeds.rb", <<~RB
    admin_password = SecureRandom.alphanumeric(16)
    User.find_or_create_by!(email: "admin@example.com") do |user|
      user.password = admin_password
      user.admin = true
    end
    puts "Admin user: admin@example.com / \#{admin_password}"
  RB
end
