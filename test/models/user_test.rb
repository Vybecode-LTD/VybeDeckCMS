require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "byline returns display_name when set" do
    user = User.new(email_address: "user@test.com", password: "password", display_name: "Jane Doe")
    assert_equal "Jane Doe", user.byline
  end

  test "byline falls back to email_address when display_name is blank" do
    user = User.new(email_address: "user@test.com", password: "password")
    assert_equal "user@test.com", user.byline
  end

  # ── Role enum values ────────────────────────────────────────────────────────
  # Use User.roles[] to verify the integer mapping — role_before_type_cast
  # returns the symbol on unsaved records in Rails 7.1+.

  test "author role maps to integer 0" do
    assert_equal 0, User.roles[:author]
    assert User.new(role: :author).author?
  end

  test "editor role maps to integer 1" do
    assert_equal 1, User.roles[:editor]
    assert User.new(role: :editor).editor?
  end

  test "admin role maps to integer 2" do
    assert_equal 2, User.roles[:admin]
    assert User.new(role: :admin).admin?
  end

  test "member role maps to integer 3" do
    assert_equal 3, User.roles[:member]
    assert User.new(role: :member).member?
  end

  test "subscriber role maps to integer 4" do
    assert_equal 4, User.roles[:subscriber]
    assert User.new(role: :subscriber).subscriber?
  end

  test "default role is author" do
    user = User.new
    assert user.author?, "expected new user to default to author role"
  end

  # ── Role helper methods ─────────────────────────────────────────────────────

  test "admin_accessible? is true for editor" do
    assert User.new(role: :editor).admin_accessible?
  end

  test "admin_accessible? is true for admin" do
    assert User.new(role: :admin).admin_accessible?
  end

  test "admin_accessible? is false for author" do
    assert_not User.new(role: :author).admin_accessible?
  end

  test "admin_accessible? is false for member" do
    assert_not User.new(role: :member).admin_accessible?
  end

  test "admin_accessible? is false for subscriber" do
    assert_not User.new(role: :subscriber).admin_accessible?
  end

  test "content_creator? is true for author" do
    assert User.new(role: :author).content_creator?
  end

  test "content_creator? is true for editor" do
    assert User.new(role: :editor).content_creator?
  end

  test "content_creator? is true for admin" do
    assert User.new(role: :admin).content_creator?
  end

  test "content_creator? is false for member" do
    assert_not User.new(role: :member).content_creator?
  end

  test "content_creator? is false for subscriber" do
    assert_not User.new(role: :subscriber).content_creator?
  end

  # ── Email verification helpers ──────────────────────────────────────────────

  test "email_verified? returns false when email_verified_at is nil" do
    user = User.new
    assert_not user.email_verified?
  end

  test "email_verified? returns true when email_verified_at is set" do
    user = User.new(email_verified_at: Time.current)
    assert user.email_verified?
  end

  # ── Ban helpers ─────────────────────────────────────────────────────────────

  test "banned? returns false when banned_at is nil" do
    user = User.new
    assert_not user.banned?
  end

  test "banned? returns true when banned_at is set" do
    user = User.new(banned_at: Time.current)
    assert user.banned?
  end

  test "ban! sets banned_at" do
    user = User.create!(email_address: "ban-#{SecureRandom.hex(4)}@test.com", password: "password")
    assert_not user.banned?
    user.ban!
    assert user.banned?
    assert_not_nil user.banned_at
  end

  test "unban! clears banned_at" do
    user = User.create!(
      email_address: "unban-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      banned_at:     Time.current
    )
    assert user.banned?
    user.unban!
    assert_not user.banned?
    assert_nil user.reload.banned_at
  end
end
