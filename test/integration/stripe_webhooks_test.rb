require "test_helper"
require "ostruct"

# Tests for StripeWebhooksController.
# Stripe::Webhook.construct_event is replaced via define_singleton_method in
# with_construct_event so no real Stripe API calls or HMAC verification occur.
class StripeWebhooksTest < ActionDispatch::IntegrationTest
  # Temporarily replaces Stripe::Webhook.construct_event for the duration of
  # the block.  Pass an Exception instance to simulate a verification failure;
  # pass any other value to return it as the parsed event.
  def with_construct_event(result_or_error)
    original = Stripe::Webhook.method(:construct_event)
    Stripe::Webhook.define_singleton_method(:construct_event) do |*_args|
      if result_or_error.is_a?(Exception)
        raise result_or_error
      else
        result_or_error
      end
    end
    yield
  ensure
    Stripe::Webhook.define_singleton_method(:construct_event, original)
  end

  # Builds an OpenStruct that mimics a minimal Stripe::Event.
  def fake_event(type, obj_attrs = {})
    obj  = OpenStruct.new(obj_attrs)
    data = OpenStruct.new(object: obj)
    OpenStruct.new(type: type, data: data)
  end

  def post_webhook(event_or_error)
    with_construct_event(event_or_error) do
      post webhooks_stripe_path,
           params:  "{}",
           headers: { "CONTENT_TYPE" => "application/json",
                      "HTTP_STRIPE_SIGNATURE" => "test_sig" }
    end
  end

  setup do
    @order = Order.create!(
      email:                    "webhook-test@example.com",
      total_cents:              1000,
      currency:                 "gbp",
      status:                   :pending,
      stripe_payment_intent_id: "pi_test_webhook_001"
    )
  end

  # ── payment_intent.succeeded ───────────────────────────────────────────────

  test "payment_intent.succeeded marks order as paid" do
    event = fake_event("payment_intent.succeeded", id: "pi_test_webhook_001")
    post_webhook(event)

    assert_response :ok
    assert_equal "paid", @order.reload.status
  end

  test "payment_intent.succeeded is a no-op when order not found" do
    event = fake_event("payment_intent.succeeded", id: "pi_nonexistent")
    assert_nothing_raised { post_webhook(event) }
    assert_response :ok
    assert_equal "pending", @order.reload.status
  end

  # ── payment_intent.payment_failed ─────────────────────────────────────────

  test "payment_intent.payment_failed marks order as failed" do
    event = fake_event("payment_intent.payment_failed", id: "pi_test_webhook_001")
    post_webhook(event)

    assert_response :ok
    assert_equal "failed", @order.reload.status
  end

  # ── charge.refunded ────────────────────────────────────────────────────────

  test "charge.refunded marks order as refunded" do
    @order.update!(status: :paid)
    event = fake_event("charge.refunded", payment_intent: "pi_test_webhook_001")
    post_webhook(event)

    assert_response :ok
    assert_equal "refunded", @order.reload.status
  end

  test "charge.refunded with no payment_intent is a no-op" do
    @order.update!(status: :paid)
    event = fake_event("charge.refunded", payment_intent: nil)
    assert_nothing_raised { post_webhook(event) }
    assert_response :ok
    assert_equal "paid", @order.reload.status
  end

  # ── Unknown event type ─────────────────────────────────────────────────────

  test "unknown event type returns 200 without modifying any order" do
    event = fake_event("customer.created", id: "cus_xyz")
    post_webhook(event)

    assert_response :ok
    assert_equal "pending", @order.reload.status
  end

  # ── Signature verification failure ────────────────────────────────────────

  test "bad signature returns 400" do
    error = Stripe::SignatureVerificationError.new("Bad signature", "test_sig")
    post_webhook(error)

    assert_response :bad_request
    assert_equal "pending", @order.reload.status
  end

  test "malformed JSON returns 400" do
    error = JSON::ParserError.new("unexpected token")
    post_webhook(error)

    assert_response :bad_request
  end
end
