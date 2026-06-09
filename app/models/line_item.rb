class LineItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
  belongs_to :price

  validates :quantity,          presence: true,
                                numericality: { only_integer: true, greater_than: 0 }
  validates :unit_amount_cents, presence: true,
                                numericality: { only_integer: true, greater_than: 0 }

  # Total cost for this line in pence/cents
  def total_cents
    quantity * unit_amount_cents
  end

  # Human-readable line total, e.g. "£9.99"
  def total_display
    Product.format_money(total_cents, price.currency)
  end
end
