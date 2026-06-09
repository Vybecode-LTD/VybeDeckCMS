require "test_helper"

# Tests for the public shop (/shop, /shop/:slug) and
# admin product management (/admin/products).
class ShopTest < ActionDispatch::IntegrationTest
  setup do
    @active_product = Product.create!(
      name:   "Active Album",
      status: :active
    )
    @active_product.prices.create!(amount_cents: 1200, currency: "gbp", active: true)

    @draft_product = Product.create!(
      name:   "Draft EP",
      status: :draft
    )
  end

  # ── Public shop index ──────────────────────────────────────────────────────

  test "GET /shop returns 200 for guests" do
    get shop_path
    assert_response :ok
  end

  test "GET /shop shows active products" do
    get shop_path
    assert_response :ok
    assert_match @active_product.name, response.body
  end

  test "GET /shop does not show draft products to guests" do
    get shop_path
    assert_no_match @draft_product.name, response.body
  end

  test "GET /shop shows empty-state message when no active products" do
    Product.active.each { |p| p.update!(status: :archived) }
    get shop_path
    assert_response :ok
    assert_match "No products available", response.body
  end

  # ── Public product show ────────────────────────────────────────────────────

  test "GET /shop/:slug returns 200 for an active product" do
    get shop_product_path(@active_product.slug)
    assert_response :ok
    assert_match @active_product.name, response.body
  end

  test "GET /shop/:slug shows the formatted price" do
    get shop_product_path(@active_product.slug)
    assert_match "£12.00", response.body
  end

  test "GET /shop/:slug for unknown slug redirects to shop" do
    get shop_product_path("does-not-exist")
    assert_redirected_to shop_path
  end

  test "GET /shop/:slug for draft product redirects guest to shop" do
    get shop_product_path(@draft_product.slug)
    assert_redirected_to root_path
  end

  # ── Admin can view draft products ─────────────────────────────────────────

  test "admin can view a draft product on the public shop show page" do
    admin = User.create!(
      email_address:    "shop-admin-#{SecureRandom.hex(4)}@example.com",
      password:         "securepassword123",
      role:             :admin,
      email_verified_at: Time.current
    )
    post session_path, params: { email_address: admin.email_address, password: "securepassword123" }
    follow_redirect!

    get shop_product_path(@draft_product.slug)
    assert_response :ok
    assert_match @draft_product.name, response.body
  end

  # ── Admin product management ───────────────────────────────────────────────

  test "admin can list products at /admin/products" do
    admin = User.create!(
      email_address:    "prod-admin-#{SecureRandom.hex(4)}@example.com",
      password:         "securepassword123",
      role:             :admin,
      email_verified_at: Time.current
    )
    post session_path, params: { email_address: admin.email_address, password: "securepassword123" }
    follow_redirect!

    get admin_products_path
    assert_response :ok
  end

  test "member cannot access /admin/products" do
    member = User.create!(
      email_address:    "prod-member-#{SecureRandom.hex(4)}@example.com",
      password:         "securepassword123",
      role:             :member,
      email_verified_at: Time.current
    )
    post session_path, params: { email_address: member.email_address, password: "securepassword123" }
    follow_redirect!

    get admin_products_path
    assert_redirected_to root_path
  end

  test "guest cannot access /admin/products" do
    get admin_products_path
    assert_redirected_to new_session_path
  end
end
