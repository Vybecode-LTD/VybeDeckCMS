require "test_helper"
require "ostruct"

class AdminStripeWebhookEventsTest < ActionDispatch::IntegrationTest
  def setup
    @admin  = create_user(role: :admin)
    @editor = create_user(role: :editor)
  end

  def create_user(role:)
    User.create!(
      email_address:     "#{role}_#{SecureRandom.hex(4)}@wh.test",
      password:          "password1234",
      display_name:      "#{role.to_s.capitalize} #{SecureRandom.hex(4)}",
      role:              role,
      email_verified_at: Time.current
    )
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  def create_event(attrs = {})
    StripeWebhookEvent.create!({
      stripe_event_id: "evt_#{SecureRandom.hex(8)}",
      event_type:      "payment_intent.succeeded",
      payload:         { "id" => "evt_test", "data" => { "object" => { "id" => "pi_test" } } }
    }.merge(attrs))
  end

  # ── Auth gates ──────────────────────────────────────────────────────────────

  test "anonymous user redirected from index" do
    get admin_stripe_webhook_events_path
    assert_redirected_to new_session_path
  end

  test "editor cannot access webhook events" do
    sign_in @editor
    get admin_stripe_webhook_events_path
    assert_redirected_to root_path
  end

  test "admin can access webhook events index" do
    sign_in @admin
    get admin_stripe_webhook_events_path
    assert_response :success
  end

  # ── Index ───────────────────────────────────────────────────────────────────

  test "index shows event type and status" do
    create_event(event_type: "charge.refunded", processed_at: 1.minute.ago)
    sign_in @admin
    get admin_stripe_webhook_events_path
    assert_response :success
    assert_select "td code", /charge\.refunded/
  end

  # ── Show ────────────────────────────────────────────────────────────────────

  test "admin can view a specific event" do
    ev = create_event
    sign_in @admin
    get admin_stripe_webhook_event_path(ev)
    assert_response :success
    assert_select "code", ev.stripe_event_id
  end

  test "show page displays error message for failed events" do
    ev = create_event(error_message: "Order not found")
    sign_in @admin
    get admin_stripe_webhook_event_path(ev)
    assert_response :success
    assert_select ".admin-error", /Order not found/
  end

  # ── Replay ──────────────────────────────────────────────────────────────────

  test "admin can replay a replayable event" do
    ev = create_event(error_message: "Something failed")
    sign_in @admin
    assert_enqueued_with(job: ReplayStripeWebhookJob, args: [ev.id]) do
      post replay_admin_stripe_webhook_event_path(ev)
    end
    assert_redirected_to admin_stripe_webhook_event_path(ev)
    assert_not_nil flash[:notice]
  end

  test "cannot replay an unknown event type" do
    ev = create_event(event_type: "customer.created")
    sign_in @admin
    post replay_admin_stripe_webhook_event_path(ev)
    assert_redirected_to admin_stripe_webhook_event_path(ev)
    assert_not_nil flash[:alert]
  end

  test "editor cannot replay events" do
    ev = create_event
    sign_in @editor
    post replay_admin_stripe_webhook_event_path(ev)
    assert_redirected_to root_path
  end

  # ── Webhook controller logs events ──────────────────────────────────────────

  test "posting a real-looking webhook with event ID creates a StripeWebhookEvent" do
    event_payload = {
      "id"   => "evt_#{SecureRandom.hex(8)}",
      "type" => "payment_intent.succeeded",
      "data" => { "object" => { "id" => "pi_no_order" } }
    }
    fake = OpenStruct.new(
      type: "payment_intent.succeeded",
      data: OpenStruct.new(object: OpenStruct.new(id: "pi_no_order"))
    )

    original = Stripe::Webhook.method(:construct_event)
    Stripe::Webhook.define_singleton_method(:construct_event) { |*_| fake }

    assert_difference "StripeWebhookEvent.count", 1 do
      post webhooks_stripe_path,
           params:  event_payload.to_json,
           headers: { "CONTENT_TYPE" => "application/json",
                      "HTTP_STRIPE_SIGNATURE" => "sig" }
    end
    assert_response :ok
    ev = StripeWebhookEvent.last
    assert_equal event_payload["id"],   ev.stripe_event_id
    assert_equal "payment_intent.succeeded", ev.event_type
    assert ev.processed?
  ensure
    Stripe::Webhook.define_singleton_method(:construct_event, original)
  end

  test "duplicate event with same ID is rejected as already processed" do
    existing_event_id = "evt_duplicate_#{SecureRandom.hex(6)}"
    StripeWebhookEvent.create!(
      stripe_event_id: existing_event_id,
      event_type:      "payment_intent.succeeded",
      payload:         {},
      processed_at:    1.hour.ago
    )
    event_payload = { "id" => existing_event_id, "type" => "payment_intent.succeeded",
                      "data" => { "object" => {} } }
    fake = OpenStruct.new(type: "payment_intent.succeeded", data: OpenStruct.new(object: OpenStruct.new))
    original = Stripe::Webhook.method(:construct_event)
    Stripe::Webhook.define_singleton_method(:construct_event) { |*_| fake }

    assert_no_difference "StripeWebhookEvent.count" do
      post webhooks_stripe_path,
           params:  event_payload.to_json,
           headers: { "CONTENT_TYPE" => "application/json",
                      "HTTP_STRIPE_SIGNATURE" => "sig" }
    end
    body = JSON.parse(response.body)
    assert_equal true, body["duplicate"]
  ensure
    Stripe::Webhook.define_singleton_method(:construct_event, original)
  end
end
