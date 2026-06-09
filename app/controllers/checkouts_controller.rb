class CheckoutsController < ApplicationController
  allow_unauthenticated_access
  before_action :resume_session

  # GET /checkout
  # Renders the checkout page.  Cart must be non-empty.  The Stimulus
  # checkout_controller takes over from here to fetch a PaymentIntent via
  # POST /checkout and mount the Stripe Payment Element.
  def new
    @cart = current_cart
    return redirect_to shop_path, alert: "Your cart is empty." if @cart.empty?

    @prefilled_email      = Current.user&.email_address
    @stripe_publishable_key = ENV.fetch("STRIPE_PUBLISHABLE_KEY", "")
    skip_authorization
  end

  # POST /checkout  (JSON)
  # Creates a pending Order + LineItems from the current cart and a matching
  # Stripe PaymentIntent.  Returns { clientSecret, orderId } on success, or
  # { error } with an appropriate HTTP status on failure.
  def create
    email = params[:email].to_s.strip

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return render json: { error: "A valid email address is required." },
                    status: :unprocessable_entity
    end

    cart = current_cart
    if cart.empty?
      return render json: { error: "Your cart is empty." },
                    status: :unprocessable_entity
    end

    currency    = cart.cart_items.joins(:price).pick("prices.currency") || "gbp"
    total_cents = cart.total_cents

    order = Order.create!(
      user:        Current.user,
      email:       email,
      total_cents: total_cents,
      currency:    currency,
      status:      :pending
    )

    cart.cart_items.includes(:product, :price).each do |item|
      order.line_items.create!(
        product:           item.product,
        price:             item.price,
        quantity:          item.quantity,
        unit_amount_cents: item.price.amount_cents
      )
    end

    payment_intent = Stripe::PaymentIntent.create(
      amount:      total_cents,
      currency:    currency,
      description: "VybeDeck CMS order ##{order.id}",
      metadata:    { order_id: order.id }
    )

    order.update!(stripe_payment_intent_id: payment_intent.id)

    render json: { clientSecret: payment_intent.client_secret, orderId: order.id }

  rescue Stripe::StripeError => e
    order&.destroy
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /checkout/confirmation?payment_intent=pi_...
  # Retrieves the order linked to the PaymentIntent, verifies its status
  # with Stripe, marks it paid if needed, and clears the cart.
  def confirmation
    pi_id  = params[:payment_intent].to_s
    @order = Order.find_by(stripe_payment_intent_id: pi_id)

    return redirect_to shop_path, alert: "Order not found." unless @order

    if @order.pending?
      begin
        pi = Stripe::PaymentIntent.retrieve(pi_id)
        if pi.status == "succeeded"
          @order.update!(status: :paid)
          SendOrderConfirmationJob.perform_later(@order.id)
          wipe_cart
        end
      rescue Stripe::StripeError
        # Webhook will update status asynchronously; silently continue
      end
    end

    skip_authorization
  end

  private

    def wipe_cart
      return unless current_cart && !current_cart.empty?
      current_cart.destroy
      session.delete(:cart_id)
      @cart = nil
    end
end
