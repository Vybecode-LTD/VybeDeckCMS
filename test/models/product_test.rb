require "test_helper"

class ProductTest < ActiveSupport::TestCase
  def build_product(overrides = {})
    Product.new({
      name:   "Test Album Download",
      status: :draft
    }.merge(overrides))
  end

  # ── Validations ────────────────────────────────────────────────────────────

  test "valid with required attributes" do
    assert build_product.valid?
  end

  test "invalid without name" do
    product = build_product(name: "")
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "FriendlyId generates unique slugs for same-named products" do
    p1 = Product.create!(name: "Unique Name", status: :draft)
    p2 = Product.create!(name: "Unique Name", status: :draft)
    assert_not_equal p1.slug, p2.slug, "FriendlyId must deduplicate slugs for same-named products"
    assert_not_nil p2.slug
  end

  # ── Status enum ────────────────────────────────────────────────────────────

  test "status defaults to draft" do
    assert build_product.draft?
  end

  test "status enum has correct integer mappings" do
    assert_equal 0, Product.statuses[:draft]
    assert_equal 1, Product.statuses[:active]
    assert_equal 2, Product.statuses[:archived]
  end

  test "for_sale scope returns only active products" do
    draft    = Product.create!(name: "Draft Product",    status: :draft)
    active   = Product.create!(name: "Active Product",   status: :active)
    archived = Product.create!(name: "Archived Product", status: :archived)

    for_sale_ids = Product.for_sale.pluck(:id)
    assert_includes     for_sale_ids, active.id
    assert_not_includes for_sale_ids, draft.id
    assert_not_includes for_sale_ids, archived.id
  end

  # ── FriendlyId ─────────────────────────────────────────────────────────────

  test "generates slug from name" do
    product = Product.create!(name: "My Great Album", status: :draft)
    assert_equal "my-great-album", product.slug
  end

  test "regenerates slug when name changes" do
    product = Product.create!(name: "Old Name", status: :draft)
    product.update!(name: "New Name")
    assert_equal "new-name", product.slug
  end

  # ── active_price ───────────────────────────────────────────────────────────

  test "active_price returns the active price" do
    product = Product.create!(name: "Priced Product", status: :active)
    price   = product.prices.create!(amount_cents: 999, currency: "gbp", active: true)

    assert_equal price, product.active_price
  end

  test "active_price returns nil when no active price" do
    product = Product.create!(name: "No Price", status: :active)
    product.prices.create!(amount_cents: 999, currency: "gbp", active: false)

    assert_nil product.active_price
  end

  # ── display_price ──────────────────────────────────────────────────────────

  test "display_price formats GBP correctly" do
    product = Product.create!(name: "GBP Product", status: :active)
    product.prices.create!(amount_cents: 999, currency: "gbp", active: true)
    assert_equal "£9.99", product.display_price
  end

  test "display_price is nil when no active price" do
    product = Product.create!(name: "No Price Product", status: :draft)
    assert_nil product.display_price
  end

  # ── format_money ───────────────────────────────────────────────────────────

  test "format_money formats GBP" do
    assert_equal "£10.00", Product.format_money(1000, "gbp")
  end

  test "format_money formats USD" do
    assert_equal "$9.99", Product.format_money(999, "usd")
  end

  test "format_money formats EUR" do
    assert_equal "€5.50", Product.format_money(550, "eur")
  end
end
