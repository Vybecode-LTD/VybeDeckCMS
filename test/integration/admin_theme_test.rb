require "test_helper"

class AdminThemeTest < ActionDispatch::IntegrationTest
  def setup
    @admin  = create_user(role: :admin)
    @editor = create_user(role: :editor)
    Theme.delete_all
    Rails.cache.delete("active_theme_css")
  end

  def teardown
    Theme.delete_all
    Rails.cache.delete("active_theme_css")
  end

  def create_user(role:)
    User.create!(
      email_address:   "#{role}_theme_#{SecureRandom.hex(4)}@test.com",
      password:        "password1234",
      display_name:    "ThemeUser#{SecureRandom.hex(4)}",
      role:            role,
      email_verified_at: Time.current
    )
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  # ── Auth gates ─────────────────────────────────────────────────────────────

  test "anonymous redirected to login" do
    get admin_theme_path
    assert_redirected_to new_session_path
  end

  test "editor redirected to root" do
    sign_in @editor
    get admin_theme_path
    assert_redirected_to root_path
  end

  test "admin can view theme editor" do
    sign_in @admin
    get admin_theme_path
    assert_response :success
    assert_select "form"
  end

  # ── Save theme ─────────────────────────────────────────────────────────────

  test "admin can save theme tokens" do
    sign_in @admin
    patch admin_theme_path, params: {
      theme: {
        name: "My Theme",
        tokens: { light_accent: "#112233", dark_accent: "#aabbcc" }
      }
    }
    assert_redirected_to admin_theme_path
    theme = Theme.active_theme
    assert_equal "#112233", theme.tokens["light_accent"]
    assert_equal "#aabbcc", theme.tokens["dark_accent"]
  end

  test "invalid hex token returns unprocessable_entity" do
    sign_in @admin
    patch admin_theme_path, params: {
      theme: {
        name: "Bad Theme",
        tokens: { light_bg: "notacolor" }
      }
    }
    assert_response :unprocessable_entity
  end

  # ── Export ─────────────────────────────────────────────────────────────────

  test "admin can export theme JSON" do
    Theme.create!(name: "Export Test", active: true)
    sign_in @admin
    get export_admin_theme_path
    assert_response :success
    assert_equal "application/json", response.content_type.split(";").first
    parsed = JSON.parse(response.body)
    assert parsed.key?("light_bg")
  end

  test "editor cannot export theme" do
    sign_in @editor
    get export_admin_theme_path
    assert_redirected_to root_path
  end

  # ── Import ─────────────────────────────────────────────────────────────────

  test "admin can import theme JSON" do
    Theme.create!(name: "Import Target", active: true)
    sign_in @admin
    json_data = { "light_accent" => "#ff0000", "dark_accent" => "#0000ff" }.to_json
    file = Rack::Test::UploadedFile.new(
      StringIO.new(json_data), "application/json", original_filename: "theme.json"
    )
    post import_admin_theme_path, params: { theme_json: file }
    assert_redirected_to admin_theme_path
    theme = Theme.active_theme
    assert_equal "#ff0000", theme.tokens["light_accent"]
  end

  test "import with invalid JSON redirects with alert" do
    Theme.create!(name: "Bad Import", active: true)
    sign_in @admin
    file = Rack::Test::UploadedFile.new(
      StringIO.new("not json at all"), "application/json", false,
      original_filename: "bad.json"
    )
    post import_admin_theme_path, params: { theme_json: file }
    assert_redirected_to admin_theme_path
    assert_not_nil flash[:alert]
  end

  # ── Reset ──────────────────────────────────────────────────────────────────

  test "admin can reset theme to defaults" do
    Theme.create!(name: "Custom", tokens: { "light_bg" => "#000000" }, active: true)
    sign_in @admin
    post reset_admin_theme_path
    assert_redirected_to admin_theme_path
    assert_equal({}, Theme.active_theme.tokens)
  end

  test "editor cannot reset theme" do
    sign_in @editor
    post reset_admin_theme_path
    assert_redirected_to root_path
  end

  # ── Active theme CSS injected in layout ───────────────────────────────────

  test "active theme CSS is injected into public layout" do
    Theme.create!(name: "Injected", tokens: { "light_accent" => "#cafe01" }, active: true)
    # Use /blog (posts index) — always returns 200 without seeded pages
    get posts_path
    assert_response :success
    assert_match "#cafe01", response.body
  end
end
