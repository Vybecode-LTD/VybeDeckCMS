class StripeWebhookEvent < ApplicationRecord
  PROCESSABLE_TYPES = %w[
    payment_intent.succeeded
    payment_intent.payment_failed
    charge.refunded
  ].freeze

  validates :stripe_event_id, presence: true, uniqueness: true
  validates :event_type,      presence: true

  scope :recent,   -> { order(created_at: :desc) }
  scope :failed,   -> { where.not(error_message: nil) }
  scope :unprocessed, -> { where(processed_at: nil) }

  def processed?  = processed_at.present?
  def failed?     = error_message.present?
  def replayable? = PROCESSABLE_TYPES.include?(event_type)

  def status_label
    return "failed"    if failed?
    return "processed" if processed?
    "pending"
  end
end
