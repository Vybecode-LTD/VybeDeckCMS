require "administrate/base_dashboard"

class CategoryDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    posts: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    slug
    posts
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    posts
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    slug
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(category)
    category.name
  end
end
