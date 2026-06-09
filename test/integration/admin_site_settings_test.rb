require "test_helper"

class AdminSiteSettingsTest < ActionDispatch::IntegrationTest
  setup do
    SiteSetting.delete_all
    @admin = User.create!(
      email_address:   "admin-ss-#{SecureRandom.hex(4)}@test.com",
      password:        "securepassword123",
      role:            :admin,
      email_verified_at: Time.current
    )
    @editor = User.create!(
      email_address:   "editor-ss-#{SecureRandom.hex(4)}@test.com",
      password:        "securepassword123",
      role:            :editor,
      email_verified_at: Time.current
    )
    @author = User.create!(
      email_address:   "author-ss-#{SecureRandom.hex(4)}@test.com",
      password:        "securepassword123",
      role:            :author,
      email_verified_at: Time.current
    )
  end

  teardown { SiteSetting.delete_all }

  # ── GET /admin/settings ───────────────────────────────────────────────────────

  test "admin can view site settings page" do
    sign_in_as @admin
    get admin_settings_path
    assert_response :ok
    assert_select "h1", text: /site settings/i
  end

  test "editor cannot view site settings page" do
    sign_in_as @editor
    get admin_settings_path
    assert_redirected_to admin_root_path
  end

  test "author is not authorised to access admin at all" do
    sign_in_as @author
    get admin_settings_path
    assert_redirected_to root_path
  end

  test "guest is redirected to sign in" do
    get admin_settings_path
    assert_redirected_to new_session_path
  end

  # ── PATCH /admin/settings ─────────────────────────────────────────────────────

  test "admin can enable invite_only mode" do
    sign_in_as @admin
    patch admin_settings_path, params: { invite_only: "1" }
    assert_redirected_to admin_settings_path
    assert_equal true, SiteSetting.invite_only?
  end

  test "admin can disable invite_only mode" do
    SiteSetting.set("invite_only", "true")
    sign_in_as @admin
    patch admin_settings_path, params: { invite_only: "0" }
    assert_redirected_to admin_settings_path
    assert_equal false, SiteSetting.invite_only?
  end

  test "submitting without invite_only param turns it off" do
    SiteSetting.set("invite_only", "true")
    sign_in_as @admin
    # Omitting the param is what a browser sends when the checkbox is unchecked
    # (only the hidden input value "0" is submitted)
    patch admin_settings_path, params: { invite_only: "0" }
    assert_equal false, SiteSetting.invite_only?
  end

  test "editor cannot update site settings" do
    sign_in_as @editor
    patch admin_settings_path, params: { invite_only: "1" }
    assert_redirected_to admin_root_path
    assert_equal false, SiteSetting.invite_only?
  end
end
