require "test_helper"

class PriceTest < ActiveSupport::TestCase
  setup do
    @product = Product.create!(name: "Test Product", status: :active)
  end

  def build_price(overrides = {})
    @product.prices.build({
      amount_cents: 999,
      currency:     "gbp",
      active:       true
    }.merge(overrides))
  end

  # ── Validations ────────────────────────────────────────────────────────────

  test "valid with required attributes" do
    assert build_price.valid?
  end

  test "invalid without amount_cents" do
    price = build_price(amount_cents: nil)
    assert_not price.valid?
    assert_includes price.errors[:amount_cents], "can't be blank"
  end

  test "amount_cents must be a positive integer" do
    [ 0, -1 ].each do |bad_val|
      price = build_price(amount_cents: bad_val)
      assert_not price.valid?, "expected #{bad_val} to be invalid"
    end
    assert build_price(amount_cents: 1).valid?
  end

  test "invalid without currency" do
    price = build_price(currency: "")
    assert_not price.valid?
    assert_includes price.errors[:currency], "can't be blank"
  end

  test "currency must be supported" do
    assert_not build_price(currency: "xbt").valid?
    %w[gbp usd eur].each do |c|
      assert build_price(currency: c).valid?, "expected #{c} to be valid"
    end
  end

  # ── display_amount ─────────────────────────────────────────────────────────

  test "display_amount formats correctly" do
    price = build_price(amount_cents: 1999, currency: "gbp")
    assert_equal "£19.99", price.display_amount
  end
end
