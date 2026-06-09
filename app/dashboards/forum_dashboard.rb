require "administrate/base_dashboard"

class ForumDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:           Field::Number,
    name:         Field::String,
    slug:         Field::String,
    description:  Field::Text,
    visibility:   Field::Select.with_options(
                    collection: Forum.visibilities.keys.map { |k| [k.humanize, k] }
                  ),
    position:     Field::Number,
    icon:         Field::String,
    forum_threads: Field::HasMany,
    created_at:   Field::DateTime,
    updated_at:   Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[name visibility position created_at].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id name slug description visibility position icon
    forum_threads created_at updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[name description visibility position icon].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(forum)
    forum.name
  end
end
