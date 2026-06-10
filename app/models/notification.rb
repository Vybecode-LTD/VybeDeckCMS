class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor,     class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true

  scope :unread,  -> { where(read_at: nil) }
  scope :recent,  -> { order(created_at: :desc) }

  after_create_commit :broadcast_bell_to_recipient

  def unread?
    read_at.nil?
  end

  def mark_read!
    update!(read_at: Time.current) if unread?
  end

  private

  def broadcast_bell_to_recipient
    count = recipient.notifications.unread.count
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_user_#{recipient_id}",
      target: "notification-bell",
      partial: "shared/notification_bell",
      locals: { count: count }
    )
  end
end
