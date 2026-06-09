class ForumReply < ApplicationRecord
  belongs_to :forum_thread, counter_cache: :reply_count
  belongs_to :author, class_name: "User"
  has_rich_text :body

  validates :body, presence: true

  after_create_commit  :update_thread_last_reply_at
  after_destroy_commit :reset_thread_last_reply_at

  private

  def update_thread_last_reply_at
    forum_thread.update_column(:last_reply_at, created_at)
  end

  def reset_thread_last_reply_at
    # Guard against cascade-destroy: the parent thread may already be destroyed
    # by the time this after_destroy_commit callback fires.
    return if forum_thread.destroyed?
    latest = forum_thread.forum_replies.order(created_at: :desc).first
    forum_thread.update_column(:last_reply_at, latest&.created_at)
  end
end
