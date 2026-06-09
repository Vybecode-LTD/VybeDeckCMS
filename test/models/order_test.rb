require "test_helper"

class OrderTest < ActiveSupport::TestCase
  def build_order(overrides = {})
    Order.new({
      email:       "customer@example.com",
      total_cents: 1000,
      currency:    "gbp",
      status:      :pending
    }.merge(overrides))
  end

  # ── Validations ────────────────────────────────────────────────────────────

  test "valid with required attributes" do
    assert build_order.valid?
  end

  test "invalid without email" do
    assert_not build_order(email: "").valid?
  end

  test "email must be valid format" do
    assert_not build_order(email: "not-an-email").valid?
    assert     build_order(email: "user@example.com").valid?
  end

  test "email is normalised to lowercase" do
    order = Order.create!(email: "UPPER@EXAMPLE.COM", total_cents: 100, currency: "gbp")
    assert_equal "upper@example.com", order.email
  end

  test "total_cents must be non-negative" do
    assert_not build_order(total_cents: -1).valid?
    assert     build_order(total_cents: 0).valid?
  end

  test "currency must be supported" do
    assert_not build_order(currency: "xyz").valid?
    assert     build_order(currency: "gbp").valid?
  end

  # ── Status enum ────────────────────────────────────────────────────────────

  test "status defaults to pending" do
    assert build_order.pending?
  end

  test "status enum integer mappings" do
    assert_equal 0, Order.statuses[:pending]
    assert_equal 1, Order.statuses[:paid]
    assert_equal 2, Order.statuses[:failed]
    assert_equal 3, Order.statuses[:refunded]
  end

  # ── total_display ──────────────────────────────────────────────────────────

  test "total_display formats correctly" do
    order = build_order(total_cents: 2500, currency: "gbp")
    assert_equal "£25.00", order.total_display
  end

  # ── user is optional ───────────────────────────────────────────────────────

  test "user is optional (guest checkout)" do
    assert build_order(user: nil).valid?
  end
end
