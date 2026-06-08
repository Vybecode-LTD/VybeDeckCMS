require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email_address: Field::Email,
    password: Field::Password,
    posts: Field::HasMany,
    role: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.roles.keys }
    ),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    email_address
    role
    posts
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email_address
    posts
    role
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    email_address
    password
    role
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    user.email_address
  end
end
