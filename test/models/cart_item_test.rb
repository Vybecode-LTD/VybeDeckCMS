require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  setup do
    @product = Product.create!(name: "Download", status: :active)
    @price   = @product.prices.create!(amount_cents: 999, currency: "gbp", active: true)
    @cart    = Cart.create!
  end

  def build_item(overrides = {})
    CartItem.new({ cart: @cart, product: @product, price: @price, quantity: 1 }.merge(overrides))
  end

  test "valid with required attributes" do
    assert build_item.valid?
  end

  test "quantity must be a positive integer" do
    [0, -1].each { |q| assert_not build_item(quantity: q).valid? }
    assert build_item(quantity: 1).valid?
  end

  test "total_cents multiplies quantity by price" do
    item = build_item(quantity: 3)
    assert_equal 2997, item.total_cents
  end

  test "total_display formats correctly" do
    item = build_item(quantity: 2)
    assert_equal "£19.98", item.total_display
  end
end
