require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:                Field::Number,
    display_name:      Field::String,
    email_address:     Field::Email,
    password:          Field::Password,
    bio:               Field::Text,
    website_url:       Field::String,
    posts:             Field::HasMany,
    role:              Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.roles.keys }
    ),
    email_verified_at: Field::DateTime,
    banned_at:         Field::DateTime,
    created_at:        Field::DateTime,
    updated_at:        Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    email_address
    display_name
    role
    posts
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    display_name
    email_address
    bio
    website_url
    posts
    role
    email_verified_at
    banned_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    display_name
    email_address
    password
    bio
    website_url
    role
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    user.byline
  end
end
