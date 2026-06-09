require "test_helper"

# Tests for CheckoutsController: new (GET /checkout), create (POST /checkout),
# and confirmation (GET /checkout/confirmation).
#
# Stripe is mocked throughout via the with_stripe_payment_intent helper from
# test/test_helpers/stripe_helper.rb (included into ActionDispatch::IntegrationTest).
class CheckoutIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @product = Product.create!(name: "Checkout Test Pack", status: :active)
    @price   = @product.prices.create!(amount_cents: 999, currency: "gbp", active: true)
  end

  # ── GET /checkout ────────────────────────────────────────────────────────────

  test "GET /checkout with empty cart redirects to shop" do
    get checkout_path
    assert_redirected_to shop_path
  end

  test "GET /checkout with cart items returns 200 and shows checkout page" do
    post cart_items_path(product_id: @product.slug)
    get checkout_path
    assert_response :ok
    assert_match "Checkout", response.body
  end

  test "GET /checkout shows the cart item in the order summary" do
    post cart_items_path(product_id: @product.slug)
    get checkout_path
    assert_match @product.name, response.body
  end

  # ── POST /checkout ───────────────────────────────────────────────────────────

  test "POST /checkout creates Order and LineItem and returns clientSecret JSON" do
    post cart_items_path(product_id: @product.slug)

    with_stripe_payment_intent do |fake_pi|
      assert_difference "Order.count",    1 do
        assert_difference "LineItem.count", 1 do
          post checkout_path, params: { email: "buyer@example.com" }, as: :json
        end
      end
      assert_response :ok
      json = JSON.parse(response.body)
      assert json.key?("clientSecret"), "JSON response must include clientSecret"
      assert json.key?("orderId"),      "JSON response must include orderId"
      assert_equal "#{fake_pi.id}_secret_test", json["clientSecret"]
    end
  end

  test "POST /checkout persists the correct email, total, and currency on the order" do
    post cart_items_path(product_id: @product.slug)

    with_stripe_payment_intent do
      post checkout_path, params: { email: "Buyer@Example.COM" }, as: :json
    end

    order = Order.last
    assert_equal "buyer@example.com", order.email   # normalizes to downcase
    assert_equal 999,                 order.total_cents
    assert_equal "gbp",               order.currency
    assert order.pending?, "order should remain pending until webhook/confirmation"
  end

  test "POST /checkout stores the Stripe PaymentIntent ID on the order" do
    post cart_items_path(product_id: @product.slug)

    with_stripe_payment_intent(id: "pi_test_stored_id") do
      post checkout_path, params: { email: "buyer@example.com" }, as: :json
    end

    assert_equal "pi_test_stored_id", Order.last.stripe_payment_intent_id
  end

  test "POST /checkout with invalid email returns 422 and an error message" do
    post cart_items_path(product_id: @product.slug)
    post checkout_path, params: { email: "not-an-email" }, as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match "email", json["error"]
  end

  test "POST /checkout with blank email returns 422" do
    post cart_items_path(product_id: @product.slug)
    post checkout_path, params: { email: "" }, as: :json
    assert_response :unprocessable_entity
  end

  test "POST /checkout with empty cart returns 422 and empty-cart error" do
    # No items added — cart is empty
    post checkout_path, params: { email: "buyer@example.com" }, as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_match "empty", json["error"]
  end

  # ── GET /checkout/confirmation ───────────────────────────────────────────────

  test "GET /checkout/confirmation marks order paid when PaymentIntent succeeded" do
    order = Order.create!(
      email:                     "buyer@example.com",
      total_cents:               999,
      currency:                  "gbp",
      status:                    :pending,
      stripe_payment_intent_id: "pi_test_conf_success"
    )

    with_stripe_payment_intent(id: "pi_test_conf_success", status: "succeeded") do
      get checkout_confirmation_path(payment_intent: "pi_test_conf_success")
    end

    assert_response :ok
    assert_match "Payment confirmed", response.body
    assert order.reload.paid?, "order must be updated to paid after confirmed PaymentIntent"
  end

  test "GET /checkout/confirmation shows processing state when PaymentIntent not yet succeeded" do
    order = Order.create!(
      email:                     "buyer@example.com",
      total_cents:               999,
      currency:                  "gbp",
      status:                    :pending,
      stripe_payment_intent_id: "pi_test_conf_pending"
    )

    with_stripe_payment_intent(id: "pi_test_conf_pending", status: "requires_payment_method") do
      get checkout_confirmation_path(payment_intent: "pi_test_conf_pending")
    end

    assert_response :ok
    assert_match "processing", response.body
    assert order.reload.pending?, "order must remain pending when payment has not succeeded"
  end

  test "GET /checkout/confirmation does not re-update an already paid order" do
    order = Order.create!(
      email:                     "buyer@example.com",
      total_cents:               999,
      currency:                  "gbp",
      status:                    :paid,
      stripe_payment_intent_id: "pi_test_already_paid"
    )

    # Retrieve is not called for already-paid orders; no Stripe mock needed
    get checkout_confirmation_path(payment_intent: "pi_test_already_paid")

    assert_response :ok
    assert_match "Payment confirmed", response.body
    assert order.reload.paid?
  end

  test "GET /checkout/confirmation with unknown payment_intent redirects to shop" do
    get checkout_confirmation_path(payment_intent: "pi_does_not_exist")
    assert_redirected_to shop_path
  end
end
