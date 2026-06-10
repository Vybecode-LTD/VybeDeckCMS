require "test_helper"

# Integration tests for Phase 4.2 — reply likes and report flagging.
#
# Covers:
#  - Like toggle (like / unlike via POST)
#  - One-like-per-user enforcement
#  - Unauthenticated users cannot like or report
#  - Report submission stores reason and reported_at
#  - User cannot report their own reply
#  - Duplicate report does not raise
class CommunityReactionsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address:     "rxn-admin-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :admin,
      email_verified_at: 1.day.ago
    )
    @member = User.create!(
      email_address:     "rxn-member-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @author = User.create!(
      email_address:     "rxn-author-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @forum = Forum.create!(name: "Reactions Forum", visibility: :open, position: 50)
    @thread = ForumThread.new(title: "Reactions Thread", forum: @forum, author: @admin)
    @thread.body = "Thread body."
    @thread.save!
    @reply = ForumReply.new(forum_thread: @thread, author: @author)
    @reply.body = "A reply."
    @reply.save!
  end

  # ── Like ─────────────────────────────────────────────────────────────────

  test "authenticated user can like a reply" do
    sign_in_as @member
    assert_difference -> { @reply.reload.likes_count }, +1 do
      post like_community_reply_path(@forum.slug, @thread.id, @reply.id)
    end
    assert_response :redirect
  end

  test "liking a reply twice toggles it off (unlike)" do
    sign_in_as @member
    post like_community_reply_path(@forum.slug, @thread.id, @reply.id)
    assert_equal 1, @reply.reload.likes_count

    post like_community_reply_path(@forum.slug, @thread.id, @reply.id)
    assert_equal 0, @reply.reload.likes_count
  end

  test "anonymous user cannot like a reply" do
    post like_community_reply_path(@forum.slug, @thread.id, @reply.id)
    assert_redirected_to new_session_path
    assert_equal 0, @reply.reload.likes_count
  end

  test "like returns turbo stream when requested" do
    sign_in_as @member
    post like_community_reply_path(@forum.slug, @thread.id, @reply.id),
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :ok
    assert_match "like-reply-#{@reply.id}", response.body
  end

  test "multiple users can each like the same reply" do
    sign_in_as @member
    post like_community_reply_path(@forum.slug, @thread.id, @reply.id)
    delete session_path
    sign_in_as @admin
    post like_community_reply_path(@forum.slug, @thread.id, @reply.id)
    assert_equal 2, @reply.reload.likes_count
  end

  # ── Report ───────────────────────────────────────────────────────────────

  test "authenticated user can report a reply with a reason" do
    sign_in_as @member
    post report_community_reply_path(@forum.slug, @thread.id, @reply.id),
         params: { report_reason: "Spam content" }
    @reply.reload
    assert @reply.reported?
    assert_equal "Spam content", @reply.report_reason
  end

  test "report redirects with notice on html request" do
    sign_in_as @member
    post report_community_reply_path(@forum.slug, @thread.id, @reply.id),
         params: { report_reason: "Off-topic" }
    assert_redirected_to community_thread_path(@forum.slug, @thread.id)
    assert_match "reported", flash[:notice].downcase
  end

  test "report returns turbo stream when requested" do
    sign_in_as @member
    post report_community_reply_path(@forum.slug, @thread.id, @reply.id),
         params: { report_reason: "Hate speech" },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :ok
    assert_match "report-reply-#{@reply.id}", response.body
  end

  test "anonymous user cannot report a reply" do
    post report_community_reply_path(@forum.slug, @thread.id, @reply.id),
         params: { report_reason: "Spam" }
    assert_redirected_to new_session_path
    assert_not @reply.reload.reported?
  end

  test "user cannot report their own reply" do
    sign_in_as @author
    post report_community_reply_path(@forum.slug, @thread.id, @reply.id),
         params: { report_reason: "Testing" }
    assert_response :redirect
    assert_not @reply.reload.reported?
  end

  test "reporting an already-reported reply updates the reason" do
    @reply.report!("First reason")
    sign_in_as @member
    assert_nothing_raised do
      post report_community_reply_path(@forum.slug, @thread.id, @reply.id),
           params: { report_reason: "Updated reason" }
    end
    assert @reply.reload.reported?
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end
end
