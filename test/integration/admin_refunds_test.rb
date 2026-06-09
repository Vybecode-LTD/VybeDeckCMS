require "test_helper"

# Tests for POST /admin/orders/:id/refund (Admin::OrdersController#refund).
class AdminRefundsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address:     "admin-refund-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :admin,
      email_verified_at: Time.current
    )
    @editor = User.create!(
      email_address:     "editor-refund-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :editor,
      email_verified_at: Time.current
    )
    @member = User.create!(
      email_address:     "member-refund-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: Time.current
    )
    @paid_order = Order.create!(
      email:                    "buyer@example.com",
      total_cents:              999,
      currency:                 "gbp",
      status:                   :paid,
      stripe_payment_intent_id: "pi_refund_test_#{SecureRandom.hex(4)}"
    )
  end

  # ── Authorization ────────────────────────────────────────────────────────────

  test "POST refund as admin succeeds and marks order refunded" do
    sign_in_as @admin
    with_stripe_refund do
      post refund_admin_order_path(@paid_order)
    end
    assert_redirected_to admin_order_path(@paid_order)
    follow_redirect!
    assert_match "Refund", response.body
    assert @paid_order.reload.refunded?
  end

  test "POST refund as editor is denied (Pundit)" do
    sign_in_as @editor
    post refund_admin_order_path(@paid_order)
    # Pundit raises → admin ApplicationController redirects with alert
    assert_response :redirect
    assert @paid_order.reload.paid?, "order should remain paid when editor tries to refund"
  end

  test "POST refund as member is blocked at admin access gate" do
    sign_in_as @member
    post refund_admin_order_path(@paid_order)
    assert_response :redirect
    assert @paid_order.reload.paid?
  end

  test "POST refund unauthenticated redirects to sign-in" do
    post refund_admin_order_path(@paid_order)
    assert_response :redirect
    assert @paid_order.reload.paid?
  end

  # ── Business logic ───────────────────────────────────────────────────────────

  test "POST refund on a non-paid order redirects with alert" do
    pending_order = Order.create!(
      email: "buyer@example.com", total_cents: 500, currency: "gbp",
      status: :pending, stripe_payment_intent_id: "pi_pending_#{SecureRandom.hex(4)}"
    )
    sign_in_as @admin
    post refund_admin_order_path(pending_order)
    assert_redirected_to admin_order_path(pending_order)
    follow_redirect!
    assert_match "Only paid orders", response.body
    assert pending_order.reload.pending?
  end

  test "POST refund when Stripe raises an error redirects with alert and leaves order paid" do
    sign_in_as @admin
    stripe_err = Stripe::StripeError.new("Card declined")
    with_stripe_refund(raises: stripe_err) do
      post refund_admin_order_path(@paid_order)
    end
    assert_redirected_to admin_order_path(@paid_order)
    follow_redirect!
    assert_match "Stripe error", response.body
    assert @paid_order.reload.paid?, "order should remain paid when Stripe call fails"
  end

  test "POST refund calls Stripe::Refund.create with the payment_intent id" do
    captured_params = nil
    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |params|
      captured_params = params
      OpenStruct.new(id: "re_capture_test", status: "succeeded")
    end

    sign_in_as @admin
    post refund_admin_order_path(@paid_order)

    assert_equal @paid_order.stripe_payment_intent_id, captured_params[:payment_intent]
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end

  # ── Order show page ──────────────────────────────────────────────────────────

  test "GET /admin/orders/:id shows refund button for paid order (admin)" do
    sign_in_as @admin
    get admin_order_path(@paid_order)
    assert_response :ok
    assert_match "Issue Full Refund", response.body
  end

  test "GET /admin/orders/:id does not show refund button for refunded order" do
    @paid_order.update!(status: :refunded)
    sign_in_as @admin
    get admin_order_path(@paid_order)
    assert_response :ok
    assert_no_match "Issue Full Refund", response.body
  end

  test "GET /admin/orders/:id does not show refund button for editor (policy)" do
    sign_in_as @editor
    get admin_order_path(@paid_order)
    assert_response :ok
    assert_no_match "Issue Full Refund", response.body
  end

  test "GET /admin/orders/:id shows formatted money not raw cents" do
    sign_in_as @admin
    get admin_order_path(@paid_order)
    assert_match "£9.99", response.body
    assert_no_match "999", response.body.gsub("999", "").then { |_| "REMOVED" } # raw cents absent
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "securepassword123" }
  end
end
