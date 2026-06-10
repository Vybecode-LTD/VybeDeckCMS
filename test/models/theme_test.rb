require "test_helper"

class ThemeTest < ActiveSupport::TestCase
  def build_theme(overrides = {})
    Theme.new({ name: "Test Theme" }.merge(overrides))
  end

  test "valid theme" do
    assert build_theme.valid?
  end

  test "requires name" do
    assert_not build_theme(name: "").valid?
  end

  test "name max 100 chars" do
    assert_not build_theme(name: "a" * 101).valid?
  end

  test "rejects non-hex token values" do
    theme = build_theme(tokens: { "light_bg" => "red" })
    assert_not theme.valid?
    assert_match /light_bg/, theme.errors[:tokens].to_s
  end

  test "accepts valid hex token values" do
    theme = build_theme(tokens: { "light_bg" => "#abc123", "light_accent" => "#FF00ff" })
    assert theme.valid?
  end

  test "ignores font_ keys in hex validation" do
    theme = build_theme(tokens: { "font_family" => "Inter", "font_url" => "https://fonts.goo.com/x" })
    assert theme.valid?
  end

  test "effective_tokens merges with defaults" do
    theme = build_theme(tokens: { "light_accent" => "#123456" })
    et = theme.effective_tokens
    assert_equal "#123456", et["light_accent"]
    assert_equal Theme::ALL_DEFAULTS["light_bg"], et["light_bg"]
  end

  test "effective_tokens returns all defaults when tokens blank" do
    theme = build_theme(tokens: {})
    assert_equal Theme::ALL_DEFAULTS, theme.effective_tokens
  end

  test "to_css includes light and dark blocks" do
    css = build_theme.to_css
    assert_match ":root", css
    assert_match "prefers-color-scheme: dark", css
    assert_match "[data-color-scheme=\"dark\"]", css
  end

  test "to_css uses effective token values" do
    theme = build_theme(tokens: { "light_accent" => "#aabbcc" })
    assert_match "#aabbcc", theme.to_css
  end

  test "to_json_export returns JSON string of effective tokens" do
    theme = build_theme
    parsed = JSON.parse(theme.to_json_export)
    assert_equal Theme::ALL_DEFAULTS["light_bg"], parsed["light_bg"]
  end

  test "apply! sets active and deactivates others" do
    other = Theme.create!(name: "Other", active: true)
    theme = Theme.create!(name: "New")
    theme.apply!
    assert theme.reload.active?
    assert_not other.reload.active?
  end

  test "reset_to_defaults! clears tokens" do
    theme = Theme.create!(name: "Custom", tokens: { "light_bg" => "#000000" }, active: true)
    theme.reset_to_defaults!
    assert_equal({}, theme.reload.tokens)
  end

  test "active_theme scope finds active record" do
    theme = Theme.create!(name: "Active", active: true)
    assert_equal theme, Theme.active_theme
  end
end
