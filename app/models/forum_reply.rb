class ForumReply < ApplicationRecord
  belongs_to :forum_thread, counter_cache: :reply_count
  belongs_to :author, class_name: "User"
  has_rich_text :body
  has_many :likes, as: :likeable, dependent: :destroy

  validates :body, presence: true

  scope :reported, -> { where.not(reported_at: nil) }

  after_create_commit  :update_thread_last_reply_at
  after_create_commit  :notify_thread_author
  after_destroy_commit :reset_thread_last_reply_at

  def like!(user)
    likes.find_or_create_by!(user: user)
  end

  def unlike!(user)
    likes.find_by(user: user)&.destroy
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end

  def report!(reason)
    update!(reported_at: Time.current, report_reason: reason.presence)
  end

  def clear_report!
    update!(reported_at: nil, report_reason: nil)
  end

  def reported?
    reported_at.present?
  end

  private

  def notify_thread_author
    thread_author = forum_thread.author
    return if thread_author == author
    Notification.create!(recipient: thread_author, actor: author, notifiable: self)
  end

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
