require "administrate/base_dashboard"

class PageDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    status: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.statuses.keys }
    ),
    published_at: Field::DateTime,
    show_in_nav: Field::Boolean,
    position: Field::Number,
    hero_image: ActiveStorageField,
    body: Field::RichText,
    slug: Field::String,
    parent: Field::BelongsTo,
    children: Field::HasMany,
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
    hero_image
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title
    status
    published_at
    show_in_nav
    position
    hero_image
    body
    slug
    parent
    children
    meta_title
    meta_description
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    title
    status
    published_at
    show_in_nav
    position
    hero_image
    body
    slug
    parent
    meta_title
    meta_description
  ].freeze

  COLLECTION_FILTERS = {
    draft: ->(resources) { resources.draft },
    published: ->(resources) { resources.published },
    archived: ->(resources) { resources.archived }
  }.freeze

  def display_resource(page)
    page.title
  end
end
