require "administrate/base_dashboard"

class PriceDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:               Field::Number,
    product:          Field::BelongsTo,
    amount_cents:     Field::Number,
    currency:         Field::String,
    nickname:         Field::String,
    active:           Field::Boolean,
    stripe_price_id:  Field::String,
    created_at:       Field::DateTime,
    updated_at:       Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[product amount_cents currency active].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id product amount_cents currency nickname active stripe_price_id created_at updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[product amount_cents currency nickname active stripe_price_id].freeze

  def display_resource(price)
    "#{price.product&.name} — #{price.display_amount}"
  end
end
