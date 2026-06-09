require "test_helper"

# Tests for DownloadsController: /account/downloads (index) and
# /account/downloads/:signed_blob_id (show/serve).
class DownloadsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address:     "downloader-#{SecureRandom.hex(4)}@example.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: Time.current
    )
    @product = Product.create!(name: "Downloadable Sample Pack", status: :active)
    @price   = @product.prices.create!(amount_cents: 999, currency: "gbp", active: true)
  end

  # ── Authentication gate ──────────────────────────────────────────────────────

  test "GET /account/downloads redirects unauthenticated visitor to sign-in" do
    get account_downloads_path
    assert_response :redirect
    follow_redirect!
    assert_match(/sign.?in|log.?in|session/i, request.path)
  end

  # ── Authenticated — index ────────────────────────────────────────────────────

  test "GET /account/downloads returns 200 for authenticated user" do
    sign_in_as @user
    get account_downloads_path
    assert_response :ok
  end

  test "GET /account/downloads shows empty-state when user has no purchases" do
    sign_in_as @user
    get account_downloads_path
    assert_match "haven't purchased", response.body
  end

  test "GET /account/downloads does not show products from pending orders" do
    order = Order.create!(
      user: @user, email: @user.email_address,
      total_cents: 999, currency: "gbp",
      status: :pending, stripe_payment_intent_id: "pi_pending_dl"
    )
    order.line_items.create!(product: @product, price: @price, quantity: 1, unit_amount_cents: 999)
    attach_download_file(@product, "pending.zip")

    sign_in_as @user
    get account_downloads_path
    assert_match "haven't purchased", response.body
    assert_no_match @product.name, response.body
  end

  test "GET /account/downloads shows product and filename after paid order" do
    paid_order_with_download

    sign_in_as @user
    get account_downloads_path
    assert_response :ok
    assert_match @product.name, response.body
    assert_match "beats.zip",   response.body
  end

  test "GET /account/downloads shows file size" do
    paid_order_with_download

    sign_in_as @user
    get account_downloads_path
    assert_match "Bytes", response.body  # number_to_human_size for tiny test file
  end

  test "GET /account/downloads does not show products without download files even when purchased" do
    order = Order.create!(
      user: @user, email: @user.email_address,
      total_cents: 999, currency: "gbp",
      status: :paid, stripe_payment_intent_id: "pi_no_files"
    )
    order.line_items.create!(product: @product, price: @price, quantity: 1, unit_amount_cents: 999)
    # No download_files attached

    sign_in_as @user
    get account_downloads_path
    assert_match "haven't purchased", response.body
  end

  # ── Authenticated — blob download ────────────────────────────────────────────

  test "GET /account/downloads/:signed_id redirects (serves) for purchased product" do
    paid_order_with_download
    blob = @product.download_files.first.blob

    sign_in_as @user
    get account_download_path(blob.signed_id)
    assert_response :redirect  # redirects to Active Storage serving URL
  end

  test "GET /account/downloads/:signed_id is denied when product not purchased" do
    attach_download_file(@product, "secret.zip")
    blob = @product.download_files.first.blob

    sign_in_as @user
    get account_download_path(blob.signed_id)
    assert_redirected_to account_downloads_path
  end

  test "GET /account/downloads/:signed_id with an invalid signed_id redirects gracefully" do
    sign_in_as @user
    get account_download_path("totally-invalid-signed-id")
    assert_redirected_to account_downloads_path
  end

  test "GET /account/downloads/:signed_id for a non-product blob redirects to downloads" do
    # Attach a file to something other than a Product (e.g., a Post's cover_image)
    post_record = Post.create!(
      title: "Test Post", slug: "test-post-dl-#{SecureRandom.hex(4)}",
      author: @user, status: :draft
    )
    post_record.cover_image.attach(
      io: StringIO.new("not a product file"),
      filename: "cover.jpg",
      content_type: "image/jpeg"
    )
    blob = post_record.cover_image.blob

    sign_in_as @user
    get account_download_path(blob.signed_id)
    assert_redirected_to account_downloads_path
  end

  test "GET /account/downloads/:signed_id requires authentication" do
    attach_download_file(@product, "public_test.zip")
    blob = @product.download_files.first.blob

    get account_download_path(blob.signed_id)
    assert_response :redirect  # redirected to sign-in (not to the file)
    follow_redirect!
    assert_no_match "attachment", response.headers.to_s.downcase
  end

  # ── ActiveStorageMultiField unit ────────────────────────────────────────────

  test "ActiveStorageMultiField.permitted_attribute returns nested array for has_many_attached" do
    result = ActiveStorageMultiField.permitted_attribute(:download_files)
    assert_equal({ download_files: [] }, result)
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "securepassword123" }
  end

  def attach_download_file(product, filename)
    product.download_files.attach(
      io:           StringIO.new("fake downloadable content"),
      filename:     filename,
      content_type: "application/zip"
    )
  end

  def paid_order_with_download
    order = Order.create!(
      user: @user, email: @user.email_address,
      total_cents: 999, currency: "gbp",
      status: :paid, stripe_payment_intent_id: "pi_paid_#{SecureRandom.hex(4)}"
    )
    order.line_items.create!(
      product: @product, price: @price,
      quantity: 1, unit_amount_cents: 999
    )
    attach_download_file(@product, "beats.zip")
    order
  end
end
