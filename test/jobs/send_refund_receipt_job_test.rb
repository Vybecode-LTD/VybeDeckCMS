require "test_helper"

class SendRefundReceiptJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  setup do
    @order = Order.create!(
      email:                    "refund-job@example.com",
      status:                   :refunded,
      total_cents:              999,
      currency:                 "gbp",
      stripe_payment_intent_id: "pi_refund_job_#{SecureRandom.hex(6)}"
    )
  end

  test "delivers refund receipt for refunded order" do
    assert_emails 1 do
      SendRefundReceiptJob.perform_now(@order.id)
    end
    @order.reload
    assert_not_nil @order.refund_receipt_sent_at
  end

  test "is idempotent — does not deliver twice" do
    @order.update!(refund_receipt_sent_at: 1.hour.ago)
    assert_emails 0 do
      SendRefundReceiptJob.perform_now(@order.id)
    end
  end

  test "skips non-refunded order" do
    @order.update!(status: :paid)
    assert_emails 0 do
      SendRefundReceiptJob.perform_now(@order.id)
    end
  end

  test "skips missing order" do
    assert_emails 0 do
      SendRefundReceiptJob.perform_now(0)
    end
  end
end
