require "test_helper"

class AdminPluginSettingsTest < ActionDispatch::IntegrationTest
  def setup
    @admin  = create_user(role: :admin)
    @editor = create_user(role: :editor)
    @plugin = Plugin.create!(
      name: "Sample SEO Plugin", slug: "sample-seo",
      version: "1.0.0", status: :active
    )
    @no_settings_plugin = Plugin.create!(
      name: "No Settings Plugin", slug: "no-settings-#{SecureRandom.hex(4)}",
      version: "1.0.0", status: :installed
    )
  end

  def create_user(role:)
    User.create!(
      email_address:     "#{role}_#{SecureRandom.hex(4)}@test.com",
      password:          "password1234",
      display_name:      "#{role.to_s.capitalize}#{SecureRandom.hex(4)}",
      role:              role,
      email_verified_at: Time.current
    )
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  # ── Auth gates ─────────────────────────────────────────────────────────────

  test "anonymous user cannot view plugin settings" do
    get admin_plugin_settings_path(@plugin)
    assert_redirected_to new_session_path
  end

  test "editor cannot view plugin settings" do
    sign_in @editor
    get admin_plugin_settings_path(@plugin)
    assert_redirected_to root_path
  end

  test "admin can view plugin settings" do
    sign_in @admin
    get admin_plugin_settings_path(@plugin)
    assert_response :success
    assert_select "h1", /Settings/
  end

  # ── Settings page content ───────────────────────────────────────────────────

  test "settings page lists declared settings" do
    sign_in @admin
    get admin_plugin_settings_path(@plugin)
    assert_response :success
    # SampleSeoPlugin declares inject_generator_meta and generator_content
    assert_select "input[name='settings[inject_generator_meta]']"
    assert_select "input[name='settings[generator_content]']"
  end

  test "redirects with alert for plugin with no declared settings" do
    # Create a plugin record for a class that declares no settings.
    # The "no-settings" slug won't match any loaded Ruby class, so plugin_class
    # will be nil, which also has no declared_settings — same redirect path.
    sign_in @admin
    get admin_plugin_settings_path(@no_settings_plugin)
    assert_redirected_to admin_plugins_path
    assert_not_nil flash[:alert]
  end

  # ── Saving settings ─────────────────────────────────────────────────────────

  test "admin can save plugin settings" do
    sign_in @admin
    patch admin_plugin_settings_path(@plugin), params: {
      settings: { "inject_generator_meta" => "1", "generator_content" => "My CMS" }
    }
    assert_redirected_to admin_plugin_settings_path(@plugin)
    assert_equal "My CMS",  @plugin.reload.setting_value("generator_content")
    assert_equal true,       @plugin.reload.setting_value("inject_generator_meta")
  end

  test "unchecking a boolean saves false" do
    sign_in @admin
    # Hidden field sends "0" when checkbox is unchecked
    patch admin_plugin_settings_path(@plugin), params: {
      settings: { "inject_generator_meta" => "0" }
    }
    assert_redirected_to admin_plugin_settings_path(@plugin)
    assert_equal false, @plugin.reload.setting_value("inject_generator_meta")
  end

  test "setting_value returns declared default before any save" do
    fresh_plugin = Plugin.create!(
      name: "Sample SEO Plugin", slug: "sample-seo-fresh-#{SecureRandom.hex(4)}",
      version: "1.0.0", status: :installed
    )
    assert_nil fresh_plugin.settings["inject_generator_meta"]
    # Falls back to the declared default (true)
    pc = VybeDeck::Plugin::Registry.registered.find { |p| p.plugin_slug == "sample-seo" }
    assert pc.present?, "SampleSeoPlugin must be registered"
    deflt = pc.declared_settings.find { |s| s[:key] == "inject_generator_meta" }&.fetch(:default)
    assert_equal true, deflt
  end
end
