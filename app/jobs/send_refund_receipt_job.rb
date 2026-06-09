class SendRefundReceiptJob < ApplicationJob
  queue_as :default

  # Sends a refund receipt for a refunded order.
  # Idempotent: sets refund_receipt_sent_at atomically.
  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order&.refunded?
    return if order.refund_receipt_sent_at?

    updated = Order.where(id: order.id, refund_receipt_sent_at: nil)
                   .update_all(refund_receipt_sent_at: Time.current)
    return if updated.zero?

    OrderMailer.refund_receipt(order).deliver_now
  end
end
