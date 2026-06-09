require "test_helper"

class SendOrderConfirmationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  setup do
    @product = Product.create!(name: "Job Product", status: :active, slug: "job-prod-#{SecureRandom.hex(4)}")
    @price   = Price.create!(product: @product, amount_cents: 500, currency: "gbp", active: true)
    @order   = Order.create!(
      email:                    "job@example.com",
      status:                   :paid,
      total_cents:              500,
      currency:                 "gbp",
      stripe_payment_intent_id: "pi_job_#{SecureRandom.hex(6)}"
    )
    @order.line_items.create!(product: @product, price: @price, quantity: 1, unit_amount_cents: 500)
  end

  test "delivers confirmation email for paid order" do
    assert_emails 1 do
      SendOrderConfirmationJob.perform_now(@order.id)
    end
    @order.reload
    assert_not_nil @order.confirmation_email_sent_at
  end

  test "is idempotent — does not deliver twice" do
    @order.update!(confirmation_email_sent_at: 1.hour.ago)
    assert_emails 0 do
      SendOrderConfirmationJob.perform_now(@order.id)
    end
  end

  test "skips non-paid order" do
    @order.update!(status: :pending)
    assert_emails 0 do
      SendOrderConfirmationJob.perform_now(@order.id)
    end
  end

  test "skips missing order" do
    assert_emails 0 do
      SendOrderConfirmationJob.perform_now(0)
    end
  end

  test "also sends download_ready when order has downloadable products" do
    @product.download_files.attach(
      io: StringIO.new("binary"),
      filename: "track.zip",
      content_type: "application/zip"
    )
    assert_emails 2 do
      SendOrderConfirmationJob.perform_now(@order.id)
    end
  end

  test "does not send download_ready for non-downloadable orders" do
    assert_emails 1 do
      SendOrderConfirmationJob.perform_now(@order.id)
    end
  end
end
