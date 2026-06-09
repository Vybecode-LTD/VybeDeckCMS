require "administrate/base_dashboard"

class ForumReplyDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:           Field::Number,
    forum_thread: Field::BelongsTo,
    author:       Field::BelongsTo,
    likes_count:  Field::Number,
    is_solution:  Field::Boolean,
    created_at:   Field::DateTime,
    updated_at:   Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[forum_thread author is_solution likes_count created_at].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id forum_thread author is_solution likes_count created_at updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[is_solution].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(reply)
    "Reply ##{reply.id}"
  end
end
