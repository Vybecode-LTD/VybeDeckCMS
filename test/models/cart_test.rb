require "test_helper"

class CartModelTest < ActiveSupport::TestCase
  setup do
    @product = Product.create!(name: "Test Album", status: :active)
    @price   = @product.prices.create!(amount_cents: 1000, currency: "gbp", active: true)
    @cart    = Cart.create!
  end

  # ── add_or_update_item ─────────────────────────────────────────────────────

  test "add_or_update_item creates a new cart item" do
    item = @cart.add_or_update_item(@product, @price)
    assert item.persisted?
    assert_equal 1, item.quantity
    assert_equal @price, item.price
  end

  test "add_or_update_item increments quantity for an existing item" do
    @cart.add_or_update_item(@product, @price)
    @cart.add_or_update_item(@product, @price)
    assert_equal 1, @cart.cart_items.count
    assert_equal 2, @cart.cart_items.first.reload.quantity
  end

  test "add_or_update_item respects custom quantity" do
    item = @cart.add_or_update_item(@product, @price, quantity: 3)
    assert_equal 3, item.quantity
  end

  # ── total_cents ────────────────────────────────────────────────────────────

  test "total_cents sums quantity * price for all items" do
    p2 = Product.create!(name: "EP", status: :active)
    pr2 = p2.prices.create!(amount_cents: 500, currency: "gbp", active: true)

    @cart.add_or_update_item(@product, @price, quantity: 2)  # 2000
    @cart.add_or_update_item(p2, pr2, quantity: 1)           #  500

    assert_equal 2500, @cart.total_cents
  end

  test "total_cents is 0 for an empty cart" do
    assert_equal 0, @cart.total_cents
  end

  # ── item_count ─────────────────────────────────────────────────────────────

  test "item_count sums quantities across all items" do
    p2  = Product.create!(name: "Single",    status: :active)
    pr2 = p2.prices.create!(amount_cents: 200, currency: "gbp", active: true)

    @cart.add_or_update_item(@product, @price, quantity: 2)
    @cart.add_or_update_item(p2, pr2, quantity: 3)

    assert_equal 5, @cart.item_count
  end

  # ── merge_from ─────────────────────────────────────────────────────────────

  test "merge_from transfers items from another cart" do
    other_cart = Cart.create!
    other_cart.add_or_update_item(@product, @price, quantity: 2)

    @cart.merge_from(other_cart)

    assert_equal 2, @cart.cart_items.first.quantity
    assert_not Cart.exists?(other_cart.id), "source cart should be destroyed"
  end

  test "merge_from increments quantity when product already in target cart" do
    @cart.add_or_update_item(@product, @price, quantity: 1)

    other_cart = Cart.create!
    other_cart.add_or_update_item(@product, @price, quantity: 3)

    @cart.merge_from(other_cart)

    assert_equal 4, @cart.cart_items.first.reload.quantity
    assert_not Cart.exists?(other_cart.id)
  end

  test "merge_from is a no-op when other_cart is nil" do
    assert_nothing_raised { @cart.merge_from(nil) }
  end

  test "merge_from is a no-op when merging with self" do
    @cart.add_or_update_item(@product, @price)
    assert_nothing_raised { @cart.merge_from(@cart) }
    assert_equal 1, @cart.cart_items.count
  end

  # ── empty? ─────────────────────────────────────────────────────────────────

  test "empty? returns true for a new cart" do
    assert @cart.empty?
  end

  test "empty? returns false when items are present" do
    @cart.add_or_update_item(@product, @price)
    assert_not @cart.empty?
  end
end
