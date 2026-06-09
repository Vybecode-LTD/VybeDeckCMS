require "administrate/base_dashboard"

class OrderDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:                        Field::Number,
    user:                      Field::BelongsTo,
    email:                     Field::String,
    status:                    Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.statuses.keys }
    ),
    total_cents:               Field::Number,
    currency:                  Field::String,
    stripe_payment_intent_id:  Field::String,
    stripe_customer_id:        Field::String,
    line_items:                Field::HasMany,
    created_at:                Field::DateTime,
    updated_at:                Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id email status total_cents currency created_at].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id user email status total_cents currency
    stripe_payment_intent_id stripe_customer_id
    line_items created_at updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[].freeze   # orders are system-created; no admin create/edit form

  COLLECTION_FILTERS = {
    pending:  ->(r) { r.pending },
    paid:     ->(r) { r.paid },
    failed:   ->(r) { r.failed },
    refunded: ->(r) { r.refunded }
  }.freeze

  def display_resource(order)
    "Order ##{order.id} — #{order.email}"
  end
end
