# Handles inbound Stripe webhook events.
# Lives outside the admin namespace so it is reachable without admin auth.
# CSRF is skipped — Stripe sends raw POST bodies signed with HMAC-SHA256.
# Signature is verified via Stripe::Webhook.construct_event.
class StripeWebhooksController < ApplicationController
  allow_unauthenticated_access only: :create
  skip_before_action :verify_authenticity_token, only: :create

  def create
    payload    = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

    event = Stripe::Webhook.construct_event(
      payload, sig_header, ENV.fetch("STRIPE_WEBHOOK_SECRET", nil)
    )

    case event.type
    when "payment_intent.succeeded"
      handle_payment_intent_succeeded(event.data.object)
    when "payment_intent.payment_failed"
      handle_payment_intent_failed(event.data.object)
    when "charge.refunded"
      handle_charge_refunded(event.data.object)
    end

    render json: { received: true }

  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def handle_payment_intent_succeeded(payment_intent)
    order = Order.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless order

    order.update!(status: :paid)
    # Phase 3.5: trigger download / subscriber-unlock fulfillment here
  end

  def handle_payment_intent_failed(payment_intent)
    order = Order.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless order

    order.update!(status: :failed)
  end

  def handle_charge_refunded(charge)
    # A Charge object carries a payment_intent field (the PI id string)
    pi_id = charge.payment_intent
    return unless pi_id

    order = Order.find_by(stripe_payment_intent_id: pi_id)
    return unless order

    order.update!(status: :refunded)
  end
end
