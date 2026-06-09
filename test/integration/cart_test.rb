require "test_helper"

# Tests for the shopping cart: CartsController (show, add, update, remove)
# and cart-merge-on-login via SessionsController.
class CartIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @product = Product.create!(name: "Cart Test Album", status: :active)
    @price   = @product.prices.create!(amount_cents: 1200, currency: "gbp", active: true)
  end

  # ── Cart show page ─────────────────────────────────────────────────────────

  test "GET /cart returns 200 for anonymous visitor" do
    get cart_path
    assert_response :ok
    assert_match "Your Cart", response.body
  end

  test "GET /cart shows empty-cart message when no items" do
    get cart_path
    assert_match "Your cart is empty", response.body
  end

  # ── Add item ───────────────────────────────────────────────────────────────

  test "POST /cart/items adds a product and redirects to product show" do
    post cart_items_path(product_id: @product.slug)
    assert_redirected_to shop_product_path(@product.slug)
    follow_redirect!
    assert_match "Added to cart", response.body
  end

  test "POST /cart/items creates a cart and sets session[:cart_id]" do
    assert_difference "Cart.count", 1 do
      post cart_items_path(product_id: @product.slug)
    end
  end

  test "POST /cart/items twice increments quantity rather than creating a second item" do
    post cart_items_path(product_id: @product.slug)
    assert_difference "CartItem.count", 0 do
      post cart_items_path(product_id: @product.slug)
    end
    cart = Cart.last
    assert_equal 2, cart.cart_items.first.quantity
  end

  test "POST /cart/items for unknown product redirects to shop" do
    post cart_items_path(product_id: "no-such-product")
    assert_redirected_to shop_path
  end

  # ── Update item ────────────────────────────────────────────────────────────

  test "PATCH /cart/items/:id updates the quantity" do
    post cart_items_path(product_id: @product.slug)
    item = Cart.last.cart_items.first

    patch cart_item_path(item), params: { quantity: 5 }
    assert_redirected_to cart_path
    assert_equal 5, item.reload.quantity
  end

  test "PATCH /cart/items/:id with quantity 0 destroys the item" do
    post cart_items_path(product_id: @product.slug)
    item = Cart.last.cart_items.first

    assert_difference "CartItem.count", -1 do
      patch cart_item_path(item), params: { quantity: 0 }
    end
  end

  # ── Remove item ────────────────────────────────────────────────────────────

  test "DELETE /cart/items/:id removes the item and redirects to cart" do
    post cart_items_path(product_id: @product.slug)
    item = Cart.last.cart_items.first

    assert_difference "CartItem.count", -1 do
      delete cart_item_path(item)
    end
    assert_redirected_to cart_path
  end

  # ── Cart merge on sign-in ──────────────────────────────────────────────────

  test "anonymous cart items are merged into user cart on login" do
    # 1. Add item as anonymous visitor
    post cart_items_path(product_id: @product.slug)
    anon_cart = Cart.last
    assert_equal 1, anon_cart.cart_items.count

    # 2. Create a user and sign in
    user = User.create!(
      email_address:     "cart-merge-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: Time.current
    )
    post session_path, params: { email_address: user.email_address, password: "securepassword123" }
    follow_redirect!

    # 3. Verify items are in the user's cart and the anonymous cart is gone
    user_cart = Cart.find_by(user: user)
    assert user_cart.present?, "user should have a cart after login"
    assert_equal 1, user_cart.cart_items.count
    assert_equal @product, user_cart.cart_items.first.product
    assert_not Cart.exists?(anon_cart.id), "anonymous cart should be destroyed after merge"
  end

  test "user cart survives login when user already had a cart" do
    # 1. Create user and pre-existing user cart
    user = User.create!(
      email_address:     "cart-existing-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: Time.current
    )
    user_cart = Cart.create!(user: user)

    p2   = Product.create!(name: "Existing Cart Item", status: :active)
    pr2  = p2.prices.create!(amount_cents: 500, currency: "gbp", active: true)
    user_cart.add_or_update_item(p2, pr2, quantity: 1)

    # 2. Anonymous visitor adds a different item
    post cart_items_path(product_id: @product.slug)

    # 3. Sign in — both items should end up in the user's cart
    post session_path, params: { email_address: user.email_address, password: "securepassword123" }
    follow_redirect!

    user_cart.reload
    assert_equal 2, user_cart.cart_items.count
  end
end
