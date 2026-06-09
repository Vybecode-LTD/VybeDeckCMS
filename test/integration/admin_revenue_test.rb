require "test_helper"

# Tests for GET /admin/revenue (Admin::RevenueController#show).
class AdminRevenueTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address:     "admin-rev-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :admin,
      email_verified_at: Time.current
    )
    @editor = User.create!(
      email_address:     "editor-rev-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :editor,
      email_verified_at: Time.current
    )
    @member = User.create!(
      email_address:     "member-rev-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: Time.current
    )
  end

  # ── Authorization ────────────────────────────────────────────────────────────

  test "GET /admin/revenue returns 200 for admin" do
    sign_in_as @admin
    get admin_revenue_path
    assert_response :ok
  end

  test "GET /admin/revenue returns 200 for editor" do
    sign_in_as @editor
    get admin_revenue_path
    assert_response :ok
  end

  test "GET /admin/revenue redirects member (no admin access)" do
    sign_in_as @member
    get admin_revenue_path
    assert_response :redirect
  end

  test "GET /admin/revenue redirects unauthenticated visitor" do
    get admin_revenue_path
    assert_response :redirect
  end

  # ── Content ──────────────────────────────────────────────────────────────────

  test "GET /admin/revenue shows empty state when no paid orders" do
    sign_in_as @admin
    get admin_revenue_path
    assert_response :ok
    assert_match "No paid orders", response.body
  end

  test "GET /admin/revenue shows revenue from paid orders" do
    Order.create!(
      email: "a@example.com", total_cents: 1500, currency: "gbp",
      status: :paid, stripe_payment_intent_id: "pi_rev_1_#{SecureRandom.hex(4)}"
    )
    Order.create!(
      email: "b@example.com", total_cents: 2000, currency: "gbp",
      status: :paid, stripe_payment_intent_id: "pi_rev_2_#{SecureRandom.hex(4)}"
    )

    sign_in_as @admin
    get admin_revenue_path
    assert_response :ok
    # All-time summary card should appear
    assert_match "GBP", response.body
  end

  test "GET /admin/revenue excludes pending orders from totals" do
    Order.create!(
      email: "p@example.com", total_cents: 9999, currency: "gbp",
      status: :pending, stripe_payment_intent_id: "pi_rev_pending_#{SecureRandom.hex(4)}"
    )

    sign_in_as @admin
    get admin_revenue_path
    # Pending orders should not inflate totals — empty-state message expected
    assert_match "No paid orders", response.body
  end

  test "GET /admin/revenue shows formatted money" do
    Order.create!(
      email: "c@example.com", total_cents: 999, currency: "gbp",
      status: :paid, stripe_payment_intent_id: "pi_rev_fmt_#{SecureRandom.hex(4)}"
    )

    sign_in_as @admin
    get admin_revenue_path
    assert_match "£", response.body
  end

  test "GET /admin/revenue shows Revenue in admin navigation" do
    sign_in_as @admin
    get admin_revenue_path
    assert_match "Revenue", response.body
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "securepassword123" }
  end
end
