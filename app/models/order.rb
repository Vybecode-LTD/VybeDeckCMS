class Order < ApplicationRecord
  belongs_to :user,       optional: true   # guests may check out without an account
  has_many   :line_items, dependent: :destroy
  has_many   :products,   through: :line_items

  # pending (0) — payment not yet completed
  # paid    (1) — payment confirmed
  # failed  (2) — payment failed
  # refunded(3) — fully refunded
  enum :status, { pending: 0, paid: 1, failed: 2, refunded: 3 }, default: :pending

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email,       presence: true,
                          format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :total_cents, presence: true,
                          numericality: { only_integer: true,
                                         greater_than_or_equal_to: 0 }
  validates :currency,    presence: true,
                          inclusion: { in: Product::SUPPORTED_CURRENCIES }

  # Human-readable total, e.g. "£9.99"
  def total_display
    Product.format_money(total_cents, currency)
  end
end
