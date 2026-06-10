require "test_helper"

class PluginTest < ActiveSupport::TestCase
  def build_plugin(overrides = {})
    Plugin.new({
      name:    "Test Plugin",
      slug:    "test-plugin-#{SecureRandom.hex(4)}",
      version: "1.0.0"
    }.merge(overrides))
  end

  test "valid plugin" do
    assert build_plugin.valid?
  end

  test "requires name" do
    p = build_plugin(name: "")
    assert_not p.valid?
  end

  test "requires slug" do
    p = build_plugin(slug: "")
    assert_not p.valid?
  end

  test "slug must be lowercase alphanumeric" do
    assert     build_plugin(slug: "valid-slug").valid?
    assert     build_plugin(slug: "with_underscore").valid?
    assert_not build_plugin(slug: "Has Spaces").valid?
    assert_not build_plugin(slug: "CamelCase").valid?
    assert_not build_plugin(slug: "-starts-with-dash").valid?
  end

  test "slug is unique" do
    slug = "unique-plugin-#{SecureRandom.hex(4)}"
    Plugin.create!(name: "First", slug: slug, version: "1.0.0")
    dup = build_plugin(slug: slug)
    assert_not dup.valid?
  end

  test "default status is installed" do
    assert build_plugin.installed?
  end

  test "status enum values" do
    %w[installed active disabled].each do |s|
      p = build_plugin(status: s)
      assert p.valid?, "Expected #{s} to be valid"
    end
  end

  test "active_plugins scope" do
    a = Plugin.create!(name: "Active",   slug: "active-#{SecureRandom.hex(4)}",   version: "1.0.0", status: :active)
    d = Plugin.create!(name: "Disabled", slug: "disabled-#{SecureRandom.hex(4)}", version: "1.0.0", status: :disabled)
    assert_includes Plugin.active_plugins, a
    assert_not_includes Plugin.active_plugins, d
  end
end
