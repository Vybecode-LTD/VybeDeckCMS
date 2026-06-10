require "test_helper"

# Phase 4.4 — Notification model.
#
# Covers:
#  - Notification created when a reply is posted to another user's thread
#  - Notification NOT created when reply author == thread author (own thread)
#  - unread scope
#  - mark_read! transitions read_at
#  - unread? predicate
class NotificationTest < ActiveSupport::TestCase
  setup do
    @thread_author = User.create!(
      email_address:     "notif-owner-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @replier = User.create!(
      email_address:     "notif-replier-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @forum = Forum.create!(name: "Notif Forum", visibility: :open, position: 80)
    @thread = ForumThread.new(title: "Notif Thread", forum: @forum, author: @thread_author)
    @thread.body = "Thread body."
    @thread.save!
  end

  test "replying to another user's thread creates a notification" do
    assert_difference "Notification.count", +1 do
      reply = ForumReply.new(forum_thread: @thread, author: @replier)
      reply.body = "A reply."
      reply.save!
    end
  end

  test "replying to your own thread does not create a notification" do
    assert_no_difference "Notification.count" do
      reply = ForumReply.new(forum_thread: @thread, author: @thread_author)
      reply.body = "My own reply."
      reply.save!
    end
  end

  test "new notification is unread" do
    notification = Notification.create!(
      recipient:  @thread_author,
      actor:      @replier,
      notifiable: @thread
    )
    assert notification.unread?
    assert_nil notification.read_at
  end

  test "mark_read! sets read_at" do
    notification = Notification.create!(
      recipient:  @thread_author,
      actor:      @replier,
      notifiable: @thread
    )
    notification.mark_read!
    assert_not notification.unread?
    assert_not_nil notification.reload.read_at
  end

  test "mark_read! is idempotent" do
    notification = Notification.create!(
      recipient:  @thread_author,
      actor:      @replier,
      notifiable: @thread
    )
    first_time = Time.current
    notification.mark_read!
    original_read_at = notification.read_at
    notification.mark_read!
    assert_equal original_read_at, notification.reload.read_at
  end

  test "unread scope excludes read notifications" do
    unread = Notification.create!(recipient: @thread_author, actor: @replier, notifiable: @thread)
    read   = Notification.create!(recipient: @thread_author, actor: @replier, notifiable: @thread,
                                   read_at: 1.hour.ago)
    assert_includes     Notification.where(recipient: @thread_author).unread, unread
    assert_not_includes Notification.where(recipient: @thread_author).unread, read
  end

  test "notification belongs_to the reply as notifiable" do
    reply = ForumReply.new(forum_thread: @thread, author: @replier)
    reply.body = "Reply."
    reply.save!
    notification = Notification.where(recipient: @thread_author).last
    assert_equal reply, notification.notifiable
    assert_equal @replier, notification.actor
  end
end
