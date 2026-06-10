class NotificationsController < ApplicationController
  before_action :require_authentication

  def index
    authorize :notification, :index?
    @pagy, @notifications = pagy(
      policy_scope(Notification).includes(:actor, :notifiable).recent,
      items: 20
    )
    # Mark all unread as read and update the bell
    unread_ids = Current.user.notifications.unread.pluck(:id)
    if unread_ids.any?
      Notification.where(id: unread_ids).update_all(read_at: Time.current)
      broadcast_bell_update(0)
    end
  end

  private

  def broadcast_bell_update(count)
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications_user_#{Current.user.id}",
      target: "notification-bell",
      partial: "shared/notification_bell",
      locals: { count: count }
    )
  end
end
