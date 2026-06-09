require "test_helper"

class LineItemTest < ActiveSupport::TestCase
  setup do
    @product  = Product.create!(name: "Item Product", status: :active)
    @price    = @product.prices.create!(amount_cents: 500, currency: "gbp", active: true)
    @order    = Order.create!(email: "buyer@example.com", total_cents: 500, currency: "gbp")
  end

  def build_item(overrides = {})
    LineItem.new({
      order:            @order,
      product:          @product,
      price:            @price,
      quantity:         1,
      unit_amount_cents: 500
    }.merge(overrides))
  end

  test "valid with required attributes" do
    assert build_item.valid?
  end

  test "quantity must be a positive integer" do
    [ 0, -1 ].each do |bad|
      assert_not build_item(quantity: bad).valid?, "expected #{bad} to be invalid"
    end
    assert build_item(quantity: 1).valid?
  end

  test "unit_amount_cents must be positive" do
    assert_not build_item(unit_amount_cents: 0).valid?
    assert_not build_item(unit_amount_cents: -1).valid?
    assert     build_item(unit_amount_cents: 1).valid?
  end

  test "total_cents multiplies quantity by unit_amount_cents" do
    item = build_item(quantity: 3, unit_amount_cents: 500)
    assert_equal 1500, item.total_cents
  end

  test "total_display formats using price currency" do
    item = build_item(quantity: 2, unit_amount_cents: 500)
    assert_equal "£10.00", item.total_display
  end
end
