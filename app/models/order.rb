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

  after_commit :dispatch_complete_hook, if: :just_paid?

  def total_display
    Product.format_money(total_cents, currency)
  end

  private

  def just_paid?
    saved_change_to_status? && paid?
  end

  def dispatch_complete_hook
    VybeDeck::Plugin::Registry.dispatch(:after_order_complete, self)
  end
end
