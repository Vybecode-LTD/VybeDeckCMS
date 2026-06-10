require "test_helper"

# Phase 4.3 — per-reply delete button.
#
# Covers:
#  - Author can delete their own reply (HTML + Turbo Stream)
#  - Admin/editor can delete any reply
#  - Member cannot delete another member's reply
#  - Anonymous user is redirected to sign-in
class CommunityReplyDeleteTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address:     "del-admin-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :admin,
      email_verified_at: 1.day.ago
    )
    @author = User.create!(
      email_address:     "del-author-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @other = User.create!(
      email_address:     "del-other-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )

    @forum = Forum.create!(name: "Delete Test Forum", visibility: :open, position: 70)
    @thread = ForumThread.new(title: "Delete Test Thread", forum: @forum, author: @admin)
    @thread.body = "Thread body."
    @thread.save!

    @reply = ForumReply.new(forum_thread: @thread, author: @author)
    @reply.body = "Reply to delete."
    @reply.save!
  end

  test "reply author can delete their own reply (html)" do
    sign_in_as @author
    assert_difference "ForumReply.count", -1 do
      delete community_thread_reply_path(@forum.slug, @thread.id, @reply.id)
    end
    assert_redirected_to community_thread_path(@forum.slug, @thread.id)
    assert_match "deleted", flash[:notice].downcase
  end

  test "reply author can delete their own reply (turbo stream)" do
    sign_in_as @author
    delete community_thread_reply_path(@forum.slug, @thread.id, @reply.id),
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :ok
    assert_match "reply-#{@reply.id}", response.body
  end

  test "admin can delete any reply" do
    sign_in_as @admin
    assert_difference "ForumReply.count", -1 do
      delete community_thread_reply_path(@forum.slug, @thread.id, @reply.id)
    end
    assert_response :redirect
  end

  test "member cannot delete another member's reply" do
    sign_in_as @other
    assert_no_difference "ForumReply.count" do
      delete community_thread_reply_path(@forum.slug, @thread.id, @reply.id)
    end
  end

  test "anonymous user is redirected to sign-in" do
    assert_no_difference "ForumReply.count" do
      delete community_thread_reply_path(@forum.slug, @thread.id, @reply.id)
    end
    assert_redirected_to new_session_path
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end
end
