# ── Admin user ────────────────────────────────────────────────────────────────
# Credentials read from env vars so this file is safe to run in production.
# Set ADMIN_EMAIL and ADMIN_PASSWORD before first deploy; change the password
# via /settings after the first sign-in.
admin_email    = ENV.fetch("ADMIN_EMAIL",    "admin@vybedeck.test")
admin_password = ENV.fetch("ADMIN_PASSWORD", "changeme")

admin = User.find_or_initialize_by(email_address: admin_email)
admin.assign_attributes(
  role:         :admin,
  password:     admin_password,
  display_name: ENV.fetch("ADMIN_DISPLAY_NAME", "VybeDeck Admin")
)
admin.email_verified_at ||= Time.current
admin.save!

if admin.previously_new_record? && admin_password == "changeme" && Rails.env.production?
  warn "\n*** WARNING: admin created with default password. " \
       "Set ADMIN_PASSWORD and ADMIN_EMAIL env vars and redeploy. ***\n\n"
end

# Verify any existing admin-role accounts that somehow got through without
# email verification (e.g. created before this guard existed).
User.where(role: :admin, email_verified_at: nil).find_each do |u|
  u.update_columns(email_verified_at: Time.current)
end

# ── Site settings ─────────────────────────────────────────────────────────────
SiteSetting.find_or_create_by!(key: "invite_only") do |s|
  s.value       = "false"
  s.value_type  = "boolean"
  s.description = "When enabled, new user registration is disabled. Existing users can still sign in."
end

SiteSetting.find_or_create_by!(key: "robots_txt_custom") do |s|
  s.value       = ""
  s.value_type  = "string"
  s.description = "Additional lines appended to the generated robots.txt."
end

# ── Categories ────────────────────────────────────────────────────────────────
announcements = Category.find_or_create_by!(name: "Announcements")
field_notes   = Category.find_or_create_by!(name: "Field Notes")

# ── Structural pages ──────────────────────────────────────────────────────────
home = Page.find_or_initialize_by(slug: "home")
home.assign_attributes(
  title:            "VybeDeck CMS",
  slug:             "home",
  status:           :published,
  published_at:     home.published_at || 2.days.ago,
  show_in_nav:      true,
  position:         1,
  meta_title:       "VybeDeck CMS",
  meta_description: "A focused Rails 8 publishing system for public pages, editorial posts, and media-backed content."
)
home.save!
home.body = <<~HTML if home.body.to_plain_text.blank?
  <h2>Publish with a quiet, durable workflow.</h2>
  <p>VybeDeck CMS keeps public pages and dated posts separate, gives editors a clear admin surface, and serves content through fast Hotwire views.</p>
HTML

about = Page.find_or_initialize_by(slug: "about")
about.assign_attributes(
  title:            "About",
  slug:             "about",
  status:           :published,
  published_at:     about.published_at || 1.day.ago,
  show_in_nav:      true,
  position:         2,
  meta_title:       "About VybeDeck CMS",
  meta_description: "Editorial structure, public publishing, and admin controls in one Rails application."
)
about.save!
about.body = <<~HTML if about.body.to_plain_text.blank?
  <p>VybeDeck CMS is an island Rails app with its own database, own authentication, and a public surface.</p>
  <p>Pages handle durable site structure. Posts handle dated editorial publishing.</p>
HTML

# ── Development / staging sample content ─────────────────────────────────────
# Skipped in production — add real content via the admin panel or a separate
# import script in db/seeds/production.rb.
unless Rails.env.production?
  require Rails.root.join("db/seeds/development")
end
