require "test_helper"

class AdminPluginsTest < ActionDispatch::IntegrationTest
  def setup
    @admin  = create_user(role: :admin)
    @editor = create_user(role: :editor)
    @member = create_user(role: :member)
  end

  def create_user(role:)
    User.create!(
      email_address: "#{role}_#{SecureRandom.hex(4)}@test.com",
      password: "password1234",
      display_name: "#{role.to_s.capitalize}#{SecureRandom.hex(4)}",
      role: role,
      email_verified_at: Time.current
    )
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  def create_plugin(attrs = {})
    Plugin.create!({
      name:    "Test Plugin",
      slug:    "test-plugin-#{SecureRandom.hex(4)}",
      version: "1.0.0",
      status:  :installed
    }.merge(attrs))
  end

  # ── Auth gates ─────────────────────────────────────────────────────────────

  test "anonymous redirected to login" do
    get admin_plugins_path
    assert_redirected_to new_session_path
  end

  test "editor cannot access plugins" do
    sign_in @editor
    get admin_plugins_path
    assert_redirected_to root_path
  end

  test "admin can access plugins index" do
    sign_in @admin
    get admin_plugins_path
    assert_response :success
  end

  # ── Activate / Deactivate ──────────────────────────────────────────────────

  test "admin can activate an installed plugin" do
    sign_in @admin
    plugin = create_plugin
    patch activate_admin_plugin_path(plugin)
    assert_redirected_to admin_plugins_path
    assert plugin.reload.active?
  end

  test "admin can deactivate an active plugin" do
    sign_in @admin
    plugin = create_plugin(status: :active)
    patch deactivate_admin_plugin_path(plugin)
    assert_redirected_to admin_plugins_path
    assert plugin.reload.disabled?
  end

  # ── Uninstall ──────────────────────────────────────────────────────────────

  test "admin can uninstall a plugin" do
    sign_in @admin
    plugin = create_plugin
    assert_difference "Plugin.count", -1 do
      delete admin_plugin_path(plugin)
    end
    assert_redirected_to admin_plugins_path
  end

  test "editor cannot uninstall a plugin" do
    sign_in @editor
    plugin = create_plugin
    assert_no_difference "Plugin.count" do
      delete admin_plugin_path(plugin)
    end
    assert_redirected_to root_path
  end

  # ── Install from registry ──────────────────────────────────────────────────

  test "admin can install a loaded plugin by slug" do
    sign_in @admin
    # SampleSeoPlugin is auto-loaded by the initializer
    assert_difference "Plugin.count", 1 do
      post admin_plugins_path, params: { plugin: { slug: "sample-seo" } }
    end
    assert_redirected_to admin_plugins_path
  end

  test "install with unknown slug redirects with alert" do
    sign_in @admin
    assert_no_difference "Plugin.count" do
      post admin_plugins_path, params: { plugin: { slug: "does-not-exist" } }
    end
    assert_redirected_to admin_plugins_path
    assert_not_nil flash[:alert]
  end
end
