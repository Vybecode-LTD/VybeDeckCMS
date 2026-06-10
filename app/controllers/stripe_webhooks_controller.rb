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

    # Log the event for the admin webhook viewer. Skipped when there is no
    # Stripe event ID (e.g., in test mocks that send an empty payload).
    parsed_payload = JSON.parse(payload)
    event_id_str   = parsed_payload["id"].to_s
    webhook_record = nil

    if event_id_str.present?
      webhook_record = StripeWebhookEvent.find_or_initialize_by(stripe_event_id: event_id_str)
      if webhook_record.persisted? && webhook_record.processed?
        return render json: { received: true, duplicate: true }
      end
      unless webhook_record.persisted?
        webhook_record.assign_attributes(event_type: event.type, payload: parsed_payload)
        webhook_record.save!
      end
    end

    case event.type
    when "payment_intent.succeeded"
      handle_payment_intent_succeeded(event.data.object)
    when "payment_intent.payment_failed"
      handle_payment_intent_failed(event.data.object)
    when "charge.refunded"
      handle_charge_refunded(event.data.object)
    end

    webhook_record&.update(processed_at: Time.current)
    render json: { received: true }

  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    render json: { error: e.message }, status: :bad_request
  end

  private

  def handle_payment_intent_succeeded(payment_intent)
    order = Order.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless order

    order.update!(status: :paid)
    SendOrderConfirmationJob.perform_later(order.id)
  end

  def handle_payment_intent_failed(payment_intent)
    order = Order.find_by(stripe_payment_intent_id: payment_intent.id)
    return unless order

    order.update!(status: :failed)
  end

  def handle_charge_refunded(charge)
    pi_id = charge.payment_intent
    return unless pi_id

    order = Order.find_by(stripe_payment_intent_id: pi_id)
    return unless order

    order.update!(status: :refunded)
  end
end
