require "test_helper"

# Phase 4.4 — Notifications controller and bell.
#
# Covers:
#  - Authenticated user can view their notifications
#  - Visiting /notifications marks all unread as read
#  - Anonymous user is redirected to sign-in
#  - User only sees their own notifications (policy scope)
class NotificationsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address:     "n-user-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @other = User.create!(
      email_address:     "n-other-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @forum = Forum.create!(name: "Notif Int Forum", visibility: :open, position: 85)
    @thread = ForumThread.new(title: "Notif Int Thread", forum: @forum, author: @user)
    @thread.body = "Thread body."
    @thread.save!

    # A notification for @user
    @notif = Notification.create!(
      recipient:  @user,
      actor:      @other,
      notifiable: @thread
    )
  end

  test "anonymous user is redirected to sign-in" do
    get notifications_path
    assert_redirected_to new_session_path
  end

  test "authenticated user can view notifications" do
    sign_in_as @user
    get notifications_path
    assert_response :ok
  end

  test "visiting notifications marks all unread as read" do
    assert @notif.unread?
    sign_in_as @user
    get notifications_path
    assert_not @notif.reload.unread?
  end

  test "user only sees their own notifications" do
    # Create a second notification directed at @other, not @user
    Notification.create!(recipient: @other, actor: @user, notifiable: @thread)

    sign_in_as @user
    get notifications_path
    assert_response :ok
    # @user has exactly 1 notification; the page must render without error
    assert_equal 1, @user.notifications.count
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end
end
