class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: %i[slugged history]

  has_many   :prices,     dependent: :destroy
  has_many   :line_items, dependent: :nullify
  belongs_to :productable, polymorphic: true, optional: true
  has_one_attached  :cover_image
  has_many_attached :download_files

  # draft (0) — not visible publicly
  # active (1) — on sale
  # archived (2) — hidden, not for sale
  enum :status, { draft: 0, active: 1, archived: 2 }, default: :draft

  SUPPORTED_CURRENCIES = %w[gbp usd eur].freeze
  CURRENCY_SYMBOLS     = { "gbp" => "£", "usd" => "$", "eur" => "€" }.freeze

  validates :name,   presence: true
  validates :status, presence: true

  scope :for_sale, -> { active }

  # Returns the single active price for this product.
  # (A product may have multiple prices in different currencies;
  #  callers can filter further if needed.)
  def active_price
    prices.find_by(active: true)
  end

  # Human-readable price string, e.g. "£9.99"
  def display_price
    p = active_price
    return nil unless p

    self.class.format_money(p.amount_cents, p.currency)
  end

  def self.format_money(cents, currency)
    symbol = CURRENCY_SYMBOLS[currency.to_s.downcase] || currency.upcase
    "#{symbol}#{'%.2f' % (cents.to_i / 100.0)}"
  end

  private

  def should_generate_new_friendly_id?
    name_changed? || super
  end
end
