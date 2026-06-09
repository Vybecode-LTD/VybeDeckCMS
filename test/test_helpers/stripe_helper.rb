require "ostruct"

# Provides with_stripe_payment_intent — temporarily replaces
# Stripe::PaymentIntent.create and .retrieve using define_singleton_method
# (Minitest 6 removed Object#stub, so we use the same pattern as
# stripe_webhooks_test.rb).
module StripeHelper
  def with_stripe_payment_intent(id: nil, status: "requires_payment_method")
    id ||= "pi_test_#{SecureRandom.hex(8)}"

    fake_intent = OpenStruct.new(
      id:            id,
      client_secret: "#{id}_secret_test",
      status:        status
    )

    create_original   = Stripe::PaymentIntent.method(:create)
    retrieve_original = Stripe::PaymentIntent.method(:retrieve)

    Stripe::PaymentIntent.define_singleton_method(:create)   { |*| fake_intent }
    Stripe::PaymentIntent.define_singleton_method(:retrieve) { |*| fake_intent }

    yield fake_intent
  ensure
    Stripe::PaymentIntent.define_singleton_method(:create,   create_original)
    Stripe::PaymentIntent.define_singleton_method(:retrieve, retrieve_original)
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include StripeHelper
end
