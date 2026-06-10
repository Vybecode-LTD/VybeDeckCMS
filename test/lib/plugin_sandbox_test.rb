require "test_helper"

class PluginSandboxTest < ActiveSupport::TestCase
  # ── SandboxViolation class ─────────────────────────────────────────────────

  test "SandboxViolation is a StandardError subclass" do
    assert VybeDeck::Plugin::SandboxViolation < StandardError
  end

  # ── validate_html! ─────────────────────────────────────────────────────────

  test "validate_html! passes on safe meta tag" do
    assert_nothing_raised do
      VybeDeck::Plugin::Sandbox.validate_html!(
        '<meta name="generator" content="VybeDeck CMS">',
        plugin_slug: "test", hook: :inject_head
      )
    end
  end

  test "validate_html! passes on nil or empty string" do
    assert_nothing_raised do
      VybeDeck::Plugin::Sandbox.validate_html!(nil,  plugin_slug: "test", hook: :inject_head)
      VybeDeck::Plugin::Sandbox.validate_html!("",   plugin_slug: "test", hook: :inject_head)
    end
  end

  test "validate_html! raises on script tag" do
    html = '<script>alert("xss")</script>'
    assert_raises(VybeDeck::Plugin::SandboxViolation) do
      VybeDeck::Plugin::Sandbox.validate_html!(html, plugin_slug: "evil", hook: :inject_head)
    end
  end

  test "validate_html! raises on javascript: URI" do
    html = '<a href="javascript:void(0)">click</a>'
    assert_raises(VybeDeck::Plugin::SandboxViolation) do
      VybeDeck::Plugin::Sandbox.validate_html!(html, plugin_slug: "evil", hook: :inject_footer)
    end
  end

  test "validate_html! raises on inline event handler" do
    html = '<div onclick="steal()">click</div>'
    assert_raises(VybeDeck::Plugin::SandboxViolation) do
      VybeDeck::Plugin::Sandbox.validate_html!(html, plugin_slug: "evil", hook: :inject_head)
    end
  end

  test "validate_html! is case-insensitive for SCRIPT tag" do
    html = "<SCRIPT>alert(1)</SCRIPT>"
    assert_raises(VybeDeck::Plugin::SandboxViolation) do
      VybeDeck::Plugin::Sandbox.validate_html!(html, plugin_slug: "evil", hook: :inject_head)
    end
  end

  # ── validate_http! ─────────────────────────────────────────────────────────

  test "validate_http! passes when host is in allowed_hosts" do
    klass = stub_plugin_class(allowed: ["api.example.com"])
    assert_nothing_raised do
      VybeDeck::Plugin::Sandbox.validate_http!("https://api.example.com/data", plugin_class: klass)
    end
  end

  test "validate_http! passes for subdomain of an allowed host" do
    klass = stub_plugin_class(allowed: ["example.com"])
    assert_nothing_raised do
      VybeDeck::Plugin::Sandbox.validate_http!("https://cdn.example.com/file", plugin_class: klass)
    end
  end

  test "validate_http! passes when wildcard * is declared" do
    klass = stub_plugin_class(allowed: ["*"])
    assert_nothing_raised do
      VybeDeck::Plugin::Sandbox.validate_http!("https://anything.random.io/", plugin_class: klass)
    end
  end

  test "validate_http! raises when host not in allowed_hosts" do
    klass = stub_plugin_class(allowed: ["api.example.com"])
    assert_raises(VybeDeck::Plugin::SandboxViolation) do
      VybeDeck::Plugin::Sandbox.validate_http!("https://evil.com/steal", plugin_class: klass)
    end
  end

  test "validate_http! raises when allowed_hosts is empty" do
    klass = stub_plugin_class(allowed: [])
    assert_raises(VybeDeck::Plugin::SandboxViolation) do
      VybeDeck::Plugin::Sandbox.validate_http!("https://example.com", plugin_class: klass)
    end
  end

  # ── Registry integration ───────────────────────────────────────────────────

  test "Registry#render_hook suppresses output from plugin with forbidden HTML" do
    slug = "sandbox-evil-#{SecureRandom.hex(4)}"
    klass = Class.new do
      include VybeDeck::Plugin::Base
      def self.inject_head = '<script>alert(1)</script>'
    end
    klass.plugin_slug = slug
    plugin = Plugin.create!(name: "Evil", slug: slug, version: "1.0.0", status: :active)

    html = VybeDeck::Plugin::Registry.render_hook(:inject_head)
    refute_match "script", html
  ensure
    plugin&.destroy
    VybeDeck::Plugin::Registry.registered.delete(klass)
  end

  test "Registry#render_hook passes through clean output" do
    slug = "sandbox-clean-#{SecureRandom.hex(4)}"
    klass = Class.new do
      include VybeDeck::Plugin::Base
      def self.inject_head = '<meta name="clean-plugin" content="yes">'
    end
    klass.plugin_slug = slug
    plugin = Plugin.create!(name: "Clean", slug: slug, version: "1.0.0", status: :active)

    html = VybeDeck::Plugin::Registry.render_hook(:inject_head)
    assert_match "clean-plugin", html
  ensure
    plugin&.destroy
    VybeDeck::Plugin::Registry.registered.delete(klass)
  end

  # ── allowed_hosts class method ─────────────────────────────────────────────

  test "allowed_hosts defaults to empty array" do
    klass = Class.new { include VybeDeck::Plugin::Base }
    assert_equal [], klass.allowed_hosts
  end

  test "allowed_hosts can be set and read back" do
    klass = Class.new do
      include VybeDeck::Plugin::Base
      allowed_hosts "api.stripe.com", "cdn.example.com"
    end
    assert_equal ["api.stripe.com", "cdn.example.com"], klass.allowed_hosts
  end

  private

  def stub_plugin_class(allowed:)
    klass = Class.new { include VybeDeck::Plugin::Base }
    klass.define_singleton_method(:allowed_hosts) { allowed }
    klass.define_singleton_method(:plugin_slug)   { "stub-plugin" }
    klass
  end
end
