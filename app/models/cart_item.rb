class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  belongs_to :price

  validates :quantity, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }

  def total_cents
    quantity * price.amount_cents
  end

  def total_display
    Product.format_money(total_cents, price.currency)
  end
end
