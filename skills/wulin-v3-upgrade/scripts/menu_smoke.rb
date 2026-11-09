# frozen_string_literal: true

# Opens every menu screen the way the browser does: the layout, then the xhr=1 fetch that renders
# its grids. Signs in by stubbing ApplicationController#current_user, which both auth gems funnel
# through (wulin_oauth's from_session, wulin_auth's session user).
#
#   bin/rails runner <this skill>/scripts/menu_smoke.rb
#   LEVEL=administrator|member bin/rails runner <this skill>/scripts/menu_smoke.rb
#
# `member` stands for any level but `administrator`; under wulin_auth it is an unsaved user with
# admin false. The default runs both. With wulin_permits, a member who has no permission rows must
# be refused (401 or 403) on every screen that disappeared from their menu. Without that gem the two
# menus match, and the second pass only checks that those screens still render.

levels = if (only = ENV["LEVEL"])
  unless %w[administrator member].include?(only)
    abort "LEVEL must be administrator or member"
  end
  [only]
else
  %w[administrator member]
end

module MenuSmoke
  class << self
    attr_accessor :user, :failures
  end

  module Auth
    def current_user
      @current_user = MenuSmoke.user
    end
  end

  def self.unused_user_id
    return 1 unless defined?(UserAllPermission) && UserAllPermission.table_exists?

    used = UserAllPermission.distinct.pluck(:user_id).map(&:to_i)
    (1..).find { |i| !used.include?(i) }
  end

  def self.build_user(admin)
    email = admin ? "smoke-admin@example.com" : "smoke-member@example.com"
    if User.respond_to?(:from_session)
      return User.new(
        "id" => unused_user_id,
        "email" => email,
        "level" => (admin ? "administrator" : "member"),
        "expire_at" => (Time.now + 3600).to_i
      )
    end

    unless User.respond_to?(:new) && User.respond_to?(:columns)
      abort "menu_smoke needs wulin_oauth's User or an ActiveRecord User (wulin_auth). " \
        "The rest of the upgrade does not."
    end

    record = User.new
    record.id = unused_user_id
    record.email = email if record.respond_to?(:email=)
    record.admin = admin if record.respond_to?(:admin=)
    record.define_singleton_method(:admin?) { admin } unless record.respond_to?(:admin?) && record.admin? == admin
    record
  end

  def self.menu_document
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! "localhost"
    session.get "/"
    session.follow_redirect! if session.response.redirect?
    unless session.response.body.to_s.include?('id="menu"') || session.response.body.to_s.include?("id='menu'")
      status = session.response.status
      abort "GET / -> #{status}, and the response has no #menu. " +
        if status >= 500
          "The layout failed to render -- a table or view the app needs but db:migrate does not create? See log/#{Rails.env}.log."
        else
          "The current_user stub did not sign in."
        end
    end
    [session, Nokogiri::HTML(session.response.body)]
  end

  def self.links_from(doc)
    doc.css("#menu li.item > a[href]").filter_map { |a|
      href = a["href"]
      text = a.text.to_s.strip.gsub(/\s+/, " ")
      next if href.start_with?("#", "javascript:") || href.include?("logout")
      next unless href.start_with?("/")

      [text, href]
    }.uniq
  end

  def self.groups_from(doc)
    doc.css("#menu li.submenu > a").map { |a| a.text.to_s.strip.gsub(/\s+/, " ") }.reject { |t| t.empty? || t == "Pinned" }
  end

  def self.open_screens(session, links)
    links.each do |text, href|
      session.get href
      page = session.response.status
      session.get href + (href.include?("?") ? "&" : "?") + "xhr=1", xhr: true
      grid = session.response.status
      self.failures += 1 unless page == 200 && grid == 200
      puts format("  %-3s %-3s %-45s %s", page, grid, text[0, 45], href)
    end
  end
end

ApplicationController.prepend(MenuSmoke::Auth)
MenuSmoke.failures = 0
menus = {}

levels.each do |level|
  # Each query runs in an executor, as a request's would: an integration request resets the execution
  # context on its way out, and ActiveRecord's query log tags fail on a query made outside one.
  MenuSmoke.user = Rails.application.executor.wrap { MenuSmoke.build_user(level == "administrator") }
  session, doc = MenuSmoke.menu_document
  links = MenuSmoke.links_from(doc)
  menus[level] = links.map(&:last)
  puts "level=#{level} groups: #{MenuSmoke.groups_from(doc).join(" | ")}"
  MenuSmoke.open_screens(session, links)
end

if (admin_hrefs = menus["administrator"]) && (member_hrefs = menus["member"])
  (admin_hrefs - member_hrefs).each do |href|
    MenuSmoke.user = Rails.application.executor.wrap { MenuSmoke.build_user(false) }
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! "localhost"
    session.get href
    status = session.response.status
    denied = [401, 403].include?(status)
    MenuSmoke.failures += 1 unless denied
    puts format("  member denied %-3s %s", status, href)
  end
  puts "member menu is the admin menu (nothing for permits to hide)" if (admin_hrefs - member_hrefs).empty?
end

abort "FAILED: #{MenuSmoke.failures} check(s)" unless MenuSmoke.failures.zero?
puts "all screens rendered"
