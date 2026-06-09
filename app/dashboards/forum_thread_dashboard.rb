require "administrate/base_dashboard"

class ForumThreadDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id:           Field::Number,
    forum:        Field::BelongsTo,
    author:       Field::BelongsTo,
    title:        Field::String,
    pinned:       Field::Boolean,
    locked:       Field::Boolean,
    view_count:   Field::Number,
    reply_count:  Field::Number,
    last_reply_at: Field::DateTime,
    forum_replies: Field::HasMany,
    created_at:   Field::DateTime,
    updated_at:   Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[title forum author reply_count pinned locked created_at].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id title forum author pinned locked
    view_count reply_count last_reply_at
    forum_replies created_at updated_at
  ].freeze

  # Threads are created through the public community UI, not via admin form.
  FORM_ATTRIBUTES = %i[forum title pinned locked].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(thread)
    thread.title
  end
end
