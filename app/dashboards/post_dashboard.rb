require "administrate/base_dashboard"

class PostDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    status: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.statuses.keys }
    ),
    published_at: Field::DateTime,
    body: Field::RichText,
    slug: Field::String,
    author: Field::BelongsTo,
    categories: Field::HasMany,
    excerpt: Field::Text,
    cover_image: ActiveStorageField,
    meta_title: Field::String,
    meta_description: Field::Text,
    requires_subscriber: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    title
    author
    categories
    status
    published_at
    cover_image
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title
    status
    published_at
    requires_subscriber
    cover_image
    body
    slug
    author
    categories
    excerpt
    meta_title
    meta_description
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    title
    status
    published_at
    requires_subscriber
    cover_image
    body
    slug
    author
    categories
    excerpt
    meta_title
    meta_description
  ].freeze

  COLLECTION_FILTERS = {
    draft: ->(resources) { resources.draft },
    published: ->(resources) { resources.published },
    archived: ->(resources) { resources.archived }
  }.freeze

  def display_resource(post)
    post.title
  end
end
