require "ostruct"

# Provides Stripe test helpers that use define_singleton_method to replace
# class methods during a block (Minitest 6 removed Object#stub).
module StripeHelper
  # Replaces Stripe::PaymentIntent.create and .retrieve for the block duration.
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

  # Replaces Stripe::Refund.create for the block duration.
  # Pass raises: Stripe::StripeError.new("...") to simulate a Stripe failure.
  def with_stripe_refund(raises: nil)
    id       = "re_test_#{SecureRandom.hex(6)}"
    fake_ref = OpenStruct.new(id: id, status: "succeeded")

    original = Stripe::Refund.method(:create)
    Stripe::Refund.define_singleton_method(:create) do |*_args|
      raises ? raise(raises) : fake_ref
    end

    yield fake_ref
  ensure
    Stripe::Refund.define_singleton_method(:create, original)
  end
end

ActiveSupport.on_load(:action_dispatch_integration_test) do
  include StripeHelper
end
