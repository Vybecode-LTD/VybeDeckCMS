require "test_helper"

class UserProfileTest < ActiveSupport::TestCase
  def build_user(overrides = {})
    User.new({
      email_address: "user-#{SecureRandom.hex(4)}@test.com",
      password:      "securepassword123"
    }.merge(overrides))
  end

  def create_user(overrides = {})
    build_user(overrides).tap(&:save!)
  end

  # ── bio ──────────────────────────────────────────────────────────────────────

  test "bio is optional" do
    u = build_user
    assert u.valid?, u.errors.full_messages.inspect
  end

  test "bio may be exactly 280 characters" do
    u = build_user(bio: "a" * 280)
    assert u.valid?
  end

  test "bio over 280 characters is invalid" do
    u = build_user(bio: "a" * 281)
    assert_not u.valid?
    assert u.errors[:bio].any?
  end

  # ── website_url ──────────────────────────────────────────────────────────────

  test "website_url is optional" do
    u = build_user
    assert u.valid?
    assert_nil u.website_url
  end

  test "valid http URL is accepted" do
    u = build_user(website_url: "http://example.com")
    assert u.valid?, u.errors.full_messages.inspect
  end

  test "valid https URL is accepted" do
    u = build_user(website_url: "https://vybecod.ing")
    assert u.valid?, u.errors.full_messages.inspect
  end

  test "URL without scheme is rejected" do
    u = build_user(website_url: "example.com")
    assert_not u.valid?
    assert u.errors[:website_url].any?
  end

  test "ftp URL is rejected" do
    u = build_user(website_url: "ftp://example.com")
    assert_not u.valid?
    assert u.errors[:website_url].any?
  end

  # ── display_name uniqueness ───────────────────────────────────────────────────

  test "display_name is optional" do
    u = build_user(display_name: nil)
    assert u.valid?
  end

  test "display_name up to 50 characters is valid" do
    u = build_user(display_name: "a" * 50)
    assert u.valid?
  end

  test "display_name over 50 characters is invalid" do
    u = build_user(display_name: "a" * 51)
    assert_not u.valid?
    assert u.errors[:display_name].any?
  end

  test "duplicate display_name (same case) is rejected" do
    create_user(display_name: "AliceSmith")
    duplicate = build_user(display_name: "AliceSmith")
    assert_not duplicate.valid?
    assert duplicate.errors[:display_name].any?
  end

  test "duplicate display_name (different case) is rejected" do
    create_user(display_name: "AliceSmith")
    duplicate = build_user(display_name: "alicesmith")
    assert_not duplicate.valid?
    assert duplicate.errors[:display_name].any?
  end

  test "multiple users may have blank display_name" do
    create_user(display_name: "")
    second = build_user(display_name: "")
    assert second.valid?, second.errors.full_messages.inspect
  end

  test "multiple users may have nil display_name" do
    create_user(display_name: nil)
    second = build_user(display_name: nil)
    assert second.valid?, second.errors.full_messages.inspect
  end

  # ── byline ───────────────────────────────────────────────────────────────────

  test "byline returns display_name when present" do
    u = build_user(display_name: "JaneDoe")
    assert_equal "JaneDoe", u.byline
  end

  test "byline falls back to email_address when display_name is blank" do
    u = build_user(display_name: "")
    assert_equal u.email_address, u.byline
  end
end
