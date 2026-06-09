class SendOrderConfirmationJob < ApplicationJob
  queue_as :default

  # Sends order confirmation (and download-ready if applicable) for a paid order.
  # Idempotent: sets confirmation_email_sent_at atomically so concurrent workers
  # cannot send a second email.
  def perform(order_id)
    order = Order.find_by(id: order_id)
    return unless order&.paid?
    return if order.confirmation_email_sent_at?

    # Optimistic lock: only the worker that claims this row sends the email.
    updated = Order.where(id: order.id, confirmation_email_sent_at: nil)
                   .update_all(confirmation_email_sent_at: Time.current)
    return if updated.zero?

    OrderMailer.confirmation(order).deliver_now

    # Send a download-ready notice if any product in the order has downloadable files.
    has_downloads = order.line_items.includes(:product).any? { |li|
      li.product.download_files.attached?
    }
    OrderMailer.download_ready(order).deliver_now if has_downloads
  end
end
