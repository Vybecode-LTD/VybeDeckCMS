require "test_helper"

class SiteSettingTest < ActiveSupport::TestCase
  teardown do
    SiteSetting.delete_all
  end

  # ── get ──────────────────────────────────────────────────────────────────────

  test "get returns default value when no record exists" do
    # invite_only defaults to false
    assert_equal false, SiteSetting.get("invite_only")
  end

  test "get returns DB value when record exists" do
    SiteSetting.create!(key: "invite_only", value: "true", value_type: "boolean")
    assert_equal true, SiteSetting.get("invite_only")
  end

  test "get casts boolean true correctly" do
    SiteSetting.create!(key: "invite_only", value: "true", value_type: "boolean")
    result = SiteSetting.get("invite_only")
    assert_equal true, result
    assert_instance_of TrueClass, result
  end

  test "get casts boolean false correctly" do
    SiteSetting.create!(key: "invite_only", value: "false", value_type: "boolean")
    result = SiteSetting.get("invite_only")
    assert_equal false, result
    assert_instance_of FalseClass, result
  end

  test "get returns string for unknown key" do
    result = SiteSetting.get("unknown_key")
    assert_equal "", result
  end

  # ── set ──────────────────────────────────────────────────────────────────────

  test "set creates a new record" do
    SiteSetting.set("invite_only", "true")
    assert_equal "true", SiteSetting.find_by!(key: "invite_only").value
  end

  test "set updates an existing record" do
    SiteSetting.create!(key: "invite_only", value: "false", value_type: "boolean")
    SiteSetting.set("invite_only", "true")
    assert_equal "true", SiteSetting.find_by!(key: "invite_only").value
  end

  test "set does not create duplicate keys" do
    SiteSetting.set("invite_only", "false")
    SiteSetting.set("invite_only", "true")
    assert_equal 1, SiteSetting.where(key: "invite_only").count
  end

  # ── invite_only? ─────────────────────────────────────────────────────────────

  test "invite_only? returns false by default" do
    assert_equal false, SiteSetting.invite_only?
  end

  test "invite_only? returns true when set to true" do
    SiteSetting.set("invite_only", "true")
    assert_equal true, SiteSetting.invite_only?
  end

  test "invite_only? returns false after being turned off" do
    SiteSetting.set("invite_only", "true")
    SiteSetting.set("invite_only", "false")
    assert_equal false, SiteSetting.invite_only?
  end

  # ── validation ───────────────────────────────────────────────────────────────

  test "requires a key" do
    s = SiteSetting.new(key: "", value: "true", value_type: "boolean")
    assert_not s.valid?
    assert s.errors[:key].any?
  end

  test "requires unique key" do
    SiteSetting.create!(key: "invite_only", value: "false", value_type: "boolean")
    dup = SiteSetting.new(key: "invite_only", value: "true", value_type: "boolean")
    assert_not dup.valid?
    assert dup.errors[:key].any?
  end
end
