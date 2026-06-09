require "test_helper"

# Integration tests for Phase 4 admin forum moderation.
#
# Covers:
#  - Access control: editor/admin can reach admin forum pages; member/anon cannot
#  - Forum CRUD via Administrate
#  - ForumThread lock and pin custom actions
#  - ForumReply destroy (moderation)
class AdminForumTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address:     "admin-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :admin,
      email_verified_at: 1.day.ago
    )
    @editor = User.create!(
      email_address:     "editor-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :editor,
      email_verified_at: 1.day.ago
    )
    @member = User.create!(
      email_address:     "member-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :member,
      email_verified_at: 1.day.ago
    )

    @forum = Forum.create!(name: "Test Forum", visibility: :open, position: 1)

    @thread = ForumThread.new(
      title:  "Test Thread",
      forum:  @forum,
      author: @editor
    )
    @thread.body = "Thread body for admin tests."
    @thread.save!

    @reply = ForumReply.new(forum_thread: @thread, author: @member)
    @reply.body = "A reply to moderate."
    @reply.save!
  end

  # ── Access control ───────────────────────────────────────────────────────────

  test "anonymous visitor cannot access admin forums index" do
    get admin_forums_path
    assert_redirected_to new_session_path
  end

  test "member cannot access admin forums index" do
    sign_in_as @member
    get admin_forums_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to access the admin.", flash[:alert]
  end

  test "editor can access admin forums index" do
    sign_in_as @editor
    get admin_forums_path
    assert_response :ok
    assert_match @forum.name, response.body
  end

  test "admin can access admin forums index" do
    sign_in_as @admin
    get admin_forums_path
    assert_response :ok
  end

  # ── Forum CRUD ───────────────────────────────────────────────────────────────

  test "editor can view admin forum show page" do
    sign_in_as @editor
    get admin_forum_path(@forum)
    assert_response :ok
    assert_match @forum.name, response.body
  end

  test "editor can create a forum" do
    sign_in_as @editor
    assert_difference "Forum.count", 1 do
      post admin_forums_path, params: {
        forum: {
          name:       "New Forum",
          visibility: "open",
          position:   5
        }
      }
    end
    created = Forum.find_by!(name: "New Forum")
    assert_redirected_to admin_forum_path(created)
  end

  test "editor can update a forum" do
    sign_in_as @editor
    patch admin_forum_path(@forum), params: {
      forum: { description: "An updated description." }
    }
    assert_redirected_to admin_forum_path(@forum)
    assert_equal "An updated description.", @forum.reload.description
  end

  test "editor can destroy a forum" do
    sign_in_as @editor
    assert_difference "Forum.count", -1 do
      delete admin_forum_path(@forum)
    end
    assert_response :redirect
  end

  # ── ForumThread admin view ───────────────────────────────────────────────────

  test "editor can view admin forum_threads index" do
    sign_in_as @editor
    get admin_forum_threads_path
    assert_response :ok
    assert_match @thread.title, response.body
  end

  test "editor can view admin forum_thread show page" do
    sign_in_as @editor
    get admin_forum_thread_path(@thread)
    assert_response :ok
    assert_match @thread.title, response.body
  end

  # ── Lock / Pin custom actions ────────────────────────────────────────────────

  test "editor can lock a thread" do
    sign_in_as @editor
    assert_not @thread.locked?
    patch lock_admin_forum_thread_path(@thread)
    assert_redirected_to admin_forum_thread_path(@thread)
    assert @thread.reload.locked?
    assert_equal "Thread locked.", flash[:notice]
  end

  test "editor can unlock a thread by patching lock again" do
    @thread.update!(locked: true)
    sign_in_as @editor
    patch lock_admin_forum_thread_path(@thread)
    assert_redirected_to admin_forum_thread_path(@thread)
    assert_not @thread.reload.locked?
    assert_equal "Thread unlocked.", flash[:notice]
  end

  test "editor can pin a thread" do
    sign_in_as @editor
    assert_not @thread.pinned?
    patch pin_admin_forum_thread_path(@thread)
    assert_redirected_to admin_forum_thread_path(@thread)
    assert @thread.reload.pinned?
    assert_equal "Thread pinned.", flash[:notice]
  end

  test "editor can unpin a thread by patching pin again" do
    @thread.update!(pinned: true)
    sign_in_as @editor
    patch pin_admin_forum_thread_path(@thread)
    assert_redirected_to admin_forum_thread_path(@thread)
    assert_not @thread.reload.pinned?
    assert_equal "Thread unpinned.", flash[:notice]
  end

  test "member cannot lock a thread" do
    sign_in_as @member
    patch lock_admin_forum_thread_path(@thread)
    assert_redirected_to root_path
    assert_not @thread.reload.locked?
  end

  test "member cannot pin a thread" do
    sign_in_as @member
    patch pin_admin_forum_thread_path(@thread)
    assert_redirected_to root_path
    assert_not @thread.reload.pinned?
  end

  # ── ForumReply moderation ───────────────────────────────────────────────────

  test "editor can view admin forum_replies index" do
    sign_in_as @editor
    get admin_forum_replies_path
    assert_response :ok
  end

  test "editor can destroy a forum reply" do
    sign_in_as @editor
    assert_difference "ForumReply.count", -1 do
      delete admin_forum_reply_path(@reply)
    end
    assert_response :redirect
    assert_not ForumReply.exists?(@reply.id)
  end

  test "member cannot destroy a forum reply" do
    sign_in_as @member
    assert_no_difference "ForumReply.count" do
      delete admin_forum_reply_path(@reply)
    end
    # blocked at admin gate before Pundit even fires
    assert_response :redirect
  end
end
