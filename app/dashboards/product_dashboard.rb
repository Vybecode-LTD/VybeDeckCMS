require "administrate/base_dashboard"

class ProductDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:               Field::Number,
    name:             Field::String,
    slug:             Field::String,
    description:      Field::Text,
    status:           Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.statuses.keys }
    ),
    cover_image:      ActiveStorageField,
    download_files:   ActiveStorageMultiField,
    stripe_product_id: Field::String,
    prices:           Field::HasMany,
    created_at:       Field::DateTime,
    updated_at:       Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    status
    cover_image
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    status
    cover_image
    download_files
    description
    stripe_product_id
    prices
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    slug
    status
    cover_image
    download_files
    description
    stripe_product_id
  ].freeze

  COLLECTION_FILTERS = {
    draft:    ->(resources) { resources.draft },
    active:   ->(resources) { resources.active },
    archived: ->(resources) { resources.archived }
  }.freeze

  def display_resource(product)
    product.name
  end
end
