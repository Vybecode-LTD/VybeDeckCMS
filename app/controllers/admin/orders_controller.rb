module Admin
  class OrdersController < Admin::ApplicationController
    # POST /admin/orders/:id/refund
    def refund
      @order = Order.find(params[:id])
      authorize @order, :refund?

      unless @order.paid?
        return redirect_to [:admin, @order],
               alert: "Only paid orders can be refunded (this order is #{@order.status})."
      end

      Stripe::Refund.create(payment_intent: @order.stripe_payment_intent_id)
      @order.update!(status: :refunded)
      SendRefundReceiptJob.perform_later(@order.id)

      redirect_to [:admin, @order],
                  notice: "Refund of #{@order.total_display} issued successfully."

    rescue Stripe::StripeError => e
      redirect_to [:admin, @order],
                  alert: "Stripe error: #{e.message}"
    end
  end
end
