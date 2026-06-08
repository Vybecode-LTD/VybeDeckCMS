require "administrate/base_dashboard"

class PostDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    body: Field::RichText,
    slug: Field::String,
    author: Field::BelongsTo,
    categories: Field::HasMany,
    excerpt: Field::Text,
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
    author
    status
    published_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title
    body
    slug
    author
    categories
    excerpt
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
    author
    categories
    excerpt
    status
    published_at
    meta_title
    meta_description
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(post)
    post.title
  end
end
