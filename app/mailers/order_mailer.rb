class OrderMailer < ApplicationMailer
  # Order confirmation — sent when payment succeeds.
  def confirmation(order)
    @order      = order
    @line_items = order.line_items.includes(:product, :price)
    mail(
      to:      @order.email,
      subject: "Your VybeDeck CMS order ##{@order.id} — confirmed"
    )
  end

  # Download-ready notice — sent alongside confirmation when order
  # includes products with attached download_files.
  def download_ready(order)
    @order      = order
    @line_items = order.line_items.includes(:product).select { |li| li.product.download_files.attached? }
    mail(
      to:      @order.email,
      subject: "Your downloads are ready — order ##{@order.id}"
    )
  end

  # Refund receipt — sent after a Stripe refund is processed successfully.
  def refund_receipt(order)
    @order = order
    mail(
      to:      @order.email,
      subject: "Refund processed for order ##{@order.id}"
    )
  end
end
