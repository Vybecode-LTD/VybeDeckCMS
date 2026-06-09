require "administrate/base_dashboard"

class SeriesDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:          Field::Number,
    title:       Field::String,
    slug:        Field::String,
    description: Field::Text,
    post_count:  Field::Number,
    created_at:  Field::DateTime,
    updated_at:  Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[title post_count created_at].freeze
  SHOW_PAGE_ATTRIBUTES  = %i[title slug description post_count created_at updated_at].freeze
  FORM_ATTRIBUTES       = %i[title description].freeze

  def display_resource(series)
    series.title.presence || "Series ##{series.id}"
  end
end
