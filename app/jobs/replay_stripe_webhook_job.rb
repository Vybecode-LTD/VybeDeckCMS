# Re-runs the processing logic for a stored StripeWebhookEvent.
# Used by Admin::StripeWebhookEventsController#replay.
class ReplayStripeWebhookJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    record = StripeWebhookEvent.find_by(id: event_id)
    return unless record

    record.update!(error_message: nil, processed_at: nil,
                   replay_count: record.replay_count + 1)

    case record.event_type
    when "payment_intent.succeeded"
      pi_id = record.payload.dig("data", "object", "id")
      order = Order.find_by(stripe_payment_intent_id: pi_id)
      if order
        order.update!(status: :paid)
        SendOrderConfirmationJob.perform_later(order.id)
      end

    when "payment_intent.payment_failed"
      pi_id = record.payload.dig("data", "object", "id")
      Order.find_by(stripe_payment_intent_id: pi_id)&.update!(status: :failed)

    when "charge.refunded"
      pi_id = record.payload.dig("data", "object", "payment_intent")
      Order.find_by(stripe_payment_intent_id: pi_id)&.update!(status: :refunded)
    end

    record.update!(processed_at: Time.current)
  rescue StandardError => e
    record&.update(error_message: e.message)
    raise
  end
end
