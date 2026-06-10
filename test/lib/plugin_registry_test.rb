require "test_helper"

class PluginRegistryTest < ActiveSupport::TestCase
  def setup
    # Save and restore the registry state around each test
    @original = VybeDeck::Plugin::Registry.registered.dup
  end

  def teardown
    VybeDeck::Plugin::Registry.clear!
    @original.each { |pc| VybeDeck::Plugin::Registry.register(pc) }
  end

  test "register adds a plugin class" do
    before_count = VybeDeck::Plugin::Registry.registered.size
    klass = Class.new do
      include VybeDeck::Plugin::Base
      self.plugin_slug = "test-#{SecureRandom.hex(4)}"
    end
    assert_equal before_count + 1, VybeDeck::Plugin::Registry.registered.size
  end

  test "render_hook returns empty string when no active plugins" do
    VybeDeck::Plugin::Registry.clear!
    assert_equal "", VybeDeck::Plugin::Registry.render_hook(:inject_head)
  end

  test "render_hook aggregates output from active plugins" do
    VybeDeck::Plugin::Registry.clear!
    slug = "hook-test-#{SecureRandom.hex(4)}"
    klass = Class.new do
      include VybeDeck::Plugin::Base
      def self.inject_head = '<meta name="test">'
    end
    klass.plugin_slug = slug
    plugin = Plugin.create!(name: "Hook Test", slug: slug, version: "1.0.0", status: :active)

    html = VybeDeck::Plugin::Registry.render_hook(:inject_head)
    assert_match '<meta name="test">', html
  ensure
    plugin&.destroy
  end

  test "render_hook skips inactive plugins" do
    VybeDeck::Plugin::Registry.clear!
    slug = "inactive-#{SecureRandom.hex(4)}"
    klass = Class.new do
      include VybeDeck::Plugin::Base
      def self.inject_head = "SHOULD_NOT_APPEAR"
    end
    klass.plugin_slug = slug
    plugin = Plugin.create!(name: "Inactive", slug: slug, version: "1.0.0", status: :installed)

    html = VybeDeck::Plugin::Registry.render_hook(:inject_head)
    refute_match "SHOULD_NOT_APPEAR", html
  ensure
    plugin&.destroy
  end

  test "SampleSeoPlugin is registered on load" do
    assert_includes VybeDeck::Plugin::Registry.registered.map(&:plugin_slug), "sample-seo"
  end
end
