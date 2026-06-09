class Price < ApplicationRecord
  belongs_to :product
  has_many   :line_items, dependent: :nullify

  validates :amount_cents, presence: true,
                           numericality: { only_integer: true, greater_than: 0 }
  validates :currency, presence: true,
                       inclusion: { in: Product::SUPPORTED_CURRENCIES,
                                    message: "must be one of: %{value}" }

  # Human-readable amount, e.g. "£9.99"
  def display_amount
    Product.format_money(amount_cents, currency)
  end
end
