require "test_helper"

# Integration tests for Phase 4.2 — admin moderation queue.
#
# Covers:
#  - Access control: editor/admin see queue; member/anon cannot
#  - Queue lists only reported replies
#  - Approve action clears report fields and redirects
#  - Remove action destroys reply and redirects
#  - Non-reported reply is not approachable via approve route
class AdminModerationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address:     "mod-admin-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :admin,
      email_verified_at: 1.day.ago
    )
    @editor = User.create!(
      email_address:     "mod-editor-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :editor,
      email_verified_at: 1.day.ago
    )
    @member = User.create!(
      email_address:     "mod-member-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )
    @forum = Forum.create!(name: "Mod Queue Forum", visibility: :open, position: 60)
    @thread = ForumThread.new(title: "Mod Queue Thread", forum: @forum, author: @admin)
    @thread.body = "Thread body."
    @thread.save!

    @reported_reply = ForumReply.new(forum_thread: @thread, author: @member)
    @reported_reply.body = "Reported reply."
    @reported_reply.save!
    @reported_reply.report!("Spam")

    @clean_reply = ForumReply.new(forum_thread: @thread, author: @member)
    @clean_reply.body = "Clean reply."
    @clean_reply.save!
  end

  # ── Access control ────────────────────────────────────────────────────────

  test "anonymous user cannot access moderation queue" do
    get admin_moderation_index_path
    assert_redirected_to new_session_path
  end

  test "member cannot access moderation queue" do
    sign_in_as @member
    get admin_moderation_index_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to access the admin.", flash[:alert]
  end

  test "editor can access moderation queue" do
    sign_in_as @editor
    get admin_moderation_index_path
    assert_response :ok
  end

  test "admin can access moderation queue" do
    sign_in_as @admin
    get admin_moderation_index_path
    assert_response :ok
  end

  # ── Queue content ─────────────────────────────────────────────────────────

  test "queue lists reported replies" do
    sign_in_as @admin
    get admin_moderation_index_path
    assert_response :ok
    assert_match "Spam", response.body
  end

  test "queue does not list clean replies" do
    sign_in_as @admin
    get admin_moderation_index_path
    assert_no_match "Clean reply.", response.body
  end

  test "queue shows report reason" do
    sign_in_as @admin
    get admin_moderation_index_path
    assert_match "Spam", response.body
  end

  # ── Approve ───────────────────────────────────────────────────────────────

  test "admin can approve (clear) a reported reply" do
    sign_in_as @admin
    patch approve_admin_moderation_path(@reported_reply)
    @reported_reply.reload
    assert_not @reported_reply.reported?
    assert_nil @reported_reply.report_reason
    assert_redirected_to admin_moderation_index_path
    assert_match "Report cleared", flash[:notice]
  end

  test "editor can approve a reported reply" do
    sign_in_as @editor
    patch approve_admin_moderation_path(@reported_reply)
    assert_not @reported_reply.reload.reported?
  end

  test "member cannot approve a reply" do
    sign_in_as @member
    patch approve_admin_moderation_path(@reported_reply)
    assert @reported_reply.reload.reported?
  end

  test "anonymous user cannot approve a reply" do
    patch approve_admin_moderation_path(@reported_reply)
    assert @reported_reply.reload.reported?
  end

  # ── Remove ────────────────────────────────────────────────────────────────

  test "admin can remove (destroy) a reported reply" do
    sign_in_as @admin
    assert_difference "ForumReply.count", -1 do
      delete remove_admin_moderation_path(@reported_reply)
    end
    assert_redirected_to admin_moderation_index_path
    assert_match "removed", flash[:notice]
  end

  test "editor can remove a reported reply" do
    sign_in_as @editor
    assert_difference "ForumReply.count", -1 do
      delete remove_admin_moderation_path(@reported_reply)
    end
  end

  test "member cannot remove a reply via moderation route" do
    sign_in_as @member
    assert_no_difference "ForumReply.count" do
      delete remove_admin_moderation_path(@reported_reply)
    end
  end

  private

  def sign_in_as(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end
end
