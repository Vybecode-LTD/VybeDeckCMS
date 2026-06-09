require "administrate/base_dashboard"

# Read-only dashboard for line items — shown inline on the Order show page
# via the HasMany field. No separate admin route is registered.
class LineItemDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:               Field::Number,
    order:            Field::BelongsTo,
    product:          Field::BelongsTo,
    price:            Field::BelongsTo,
    quantity:         Field::Number,
    unit_amount_cents: Field::Number,
    created_at:       Field::DateTime,
    updated_at:       Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[product quantity unit_amount_cents].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id order product price quantity unit_amount_cents created_at updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[].freeze   # line items are system-created; no admin edit form

  def display_resource(line_item)
    "#{line_item.product&.name} × #{line_item.quantity}"
  end
end
