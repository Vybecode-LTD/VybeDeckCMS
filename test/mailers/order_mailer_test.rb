require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @product = Product.create!(name: "Test Track", status: :active, slug: "test-track-#{SecureRandom.hex(4)}")
    @price   = Price.create!(product: @product, amount_cents: 999, currency: "gbp", active: true)
    @order   = Order.create!(
      email:                       "buyer@example.com",
      status:                      :paid,
      total_cents:                 999,
      currency:                    "gbp",
      stripe_payment_intent_id:    "pi_test_mailer_#{SecureRandom.hex(6)}"
    )
    @order.line_items.create!(product: @product, price: @price, quantity: 1, unit_amount_cents: 999)
  end

  test "confirmation email renders order summary" do
    mail = OrderMailer.confirmation(@order)
    assert_equal "buyer@example.com", mail.to.first
    assert_match "confirmed", mail.subject
    decoded = mail.html_part.decoded
    assert_match "Test Track", decoded
    assert_match "9.99", decoded
  end

  test "confirmation email has text part" do
    mail = OrderMailer.confirmation(@order)
    text_decoded = mail.text_part.decoded
    assert_match "Test Track", text_decoded
  end

  test "download_ready email renders product list" do
    @product.download_files.attach(
      io: StringIO.new("binary"),
      filename: "track.zip",
      content_type: "application/zip"
    )
    mail = OrderMailer.download_ready(@order)
    assert_equal "buyer@example.com", mail.to.first
    assert_match "download", mail.subject.downcase
    assert_match "Test Track", mail.html_part.decoded
  end

  test "refund_receipt email renders amount" do
    @order.update!(status: :refunded)
    mail = OrderMailer.refund_receipt(@order)
    assert_equal "buyer@example.com", mail.to.first
    assert_match "refund", mail.subject.downcase
    assert_match "9.99", mail.html_part.decoded
  end
end
