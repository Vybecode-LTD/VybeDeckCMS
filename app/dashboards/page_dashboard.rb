require "administrate/base_dashboard"

class PageDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    body: Field::RichText,
    slug: Field::String,
    parent: Field::BelongsTo,
    children: Field::HasMany,
    position: Field::Number,
    show_in_nav: Field::Boolean,
    status: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.statuses.keys }
    ),
    published_at: Field::DateTime,
    meta_title: Field::String,
    meta_description: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    title
    status
    published_at
    show_in_nav
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title
    body
    slug
    parent
    children
    position
    show_in_nav
    status
    published_at
    meta_title
    meta_description
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    title
    body
    slug
    parent
    position
    show_in_nav
    status
    published_at
    meta_title
    meta_description
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(page)
    page.title
  end
end
