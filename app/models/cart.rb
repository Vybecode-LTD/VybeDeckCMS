class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  # Add a product to this cart, or increment its quantity if already present.
  # Always uses the product's currently active price for new items.
  def add_or_update_item(product, price, quantity: 1)
    item = cart_items.find_or_initialize_by(product: product)
    if item.persisted?
      item.increment!(:quantity, quantity)
    else
      item.price    = price
      item.quantity = quantity
      item.save!
    end
    item
  end

  # Transfer all items from other_cart into self, merging quantities for
  # duplicate products.  other_cart is destroyed after the merge.
  # Called when an anonymous session cart is adopted by a signed-in user.
  def merge_from(other_cart)
    return unless other_cart && other_cart.id != id

    other_cart.cart_items.includes(:product, :price).each do |item|
      existing = cart_items.find_by(product_id: item.product_id)
      if existing
        existing.increment!(:quantity, item.quantity)
      else
        item.update!(cart: self)
      end
    end
    other_cart.destroy
  end

  # Total price of all items, calculated in SQL.
  def total_cents
    cart_items.joins(:price)
              .sum("cart_items.quantity * prices.amount_cents")
  end

  def total_display
    return Product.format_money(0, "gbp") if cart_items.empty?
    currency = cart_items.joins(:price).pick("prices.currency") || "gbp"
    Product.format_money(total_cents, currency)
  end

  def item_count
    cart_items.sum(:quantity)
  end

  def empty?
    cart_items.none?
  end
end
