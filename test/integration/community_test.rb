require "test_helper"

# Integration tests for the public Community / Forum feature (Phase 4).
#
# Covers:
#  - Visibility gating (open / members_only / subscribers_only) for index, forum, and thread
#  - Authentication gates for write actions (new_thread, create_thread, create_reply)
#  - Thread creation and validation
#  - Reply creation via HTML and Turbo Stream
#  - Locked-thread reply guard
#  - View count increment on thread visit
class CommunityIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # ── Users ─────────────────────────────────────────────────────────────────
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
    @subscriber = User.create!(
      email_address:     "subscriber-#{SecureRandom.hex(4)}@test.com",
      password:          "password",
      role:              :subscriber,
      email_verified_at: 1.day.ago
    )

    # ── Forums ────────────────────────────────────────────────────────────────
    @open_forum = Forum.create!(
      name:       "General Discussion",
      visibility: :open,
      position:   1
    )
    @members_forum = Forum.create!(
      name:       "Members Lounge",
      visibility: :members_only,
      position:   2
    )
    @subscribers_forum = Forum.create!(
      name:       "Subscriber Circle",
      visibility: :subscribers_only,
      position:   3
    )

    # ── Threads ───────────────────────────────────────────────────────────────
    @thread = build_thread("Hello World", @open_forum, @member)
    @locked_thread = build_thread("Locked Thread", @open_forum, @admin, locked: true)
  end

  # ── Community index ─────────────────────────────────────────────────────────

  test "anonymous visitor can reach the community index" do
    get community_path
    assert_response :ok
  end

  test "community index shows only open forums to an anonymous visitor" do
    get community_path
    assert_match @open_forum.name, response.body
    assert_no_match @members_forum.name, response.body
    assert_no_match @subscribers_forum.name, response.body
  end

  test "community index shows open and members_only forums to a member" do
    sign_in_as @member
    get community_path
    assert_match @open_forum.name, response.body
    assert_match @members_forum.name, response.body
    assert_no_match @subscribers_forum.name, response.body
  end

  test "community index shows all forums to a subscriber" do
    sign_in_as @subscriber
    get community_path
    assert_match @open_forum.name, response.body
    assert_match @members_forum.name, response.body
    assert_match @subscribers_forum.name, response.body
  end

  test "community index shows all forums to an admin" do
    sign_in_as @admin
    get community_path
    assert_match @open_forum.name, response.body
    assert_match @members_forum.name, response.body
    assert_match @subscribers_forum.name, response.body
  end

  # ── Forum page ──────────────────────────────────────────────────────────────

  test "anonymous visitor can view an open forum" do
    get community_forum_path(@open_forum.slug)
    assert_response :ok
    assert_match @open_forum.name, response.body
  end

  test "anonymous visitor is redirected from a members_only forum" do
    get community_forum_path(@members_forum.slug)
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "member can view a members_only forum" do
    sign_in_as @member
    get community_forum_path(@members_forum.slug)
    assert_response :ok
    assert_match @members_forum.name, response.body
  end

  test "member is redirected from a subscribers_only forum" do
    sign_in_as @member
    get community_forum_path(@subscribers_forum.slug)
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "subscriber can view a subscribers_only forum" do
    sign_in_as @subscriber
    get community_forum_path(@subscribers_forum.slug)
    assert_response :ok
    assert_match @subscribers_forum.name, response.body
  end

  test "invalid forum slug redirects to community index" do
    get community_forum_path("does-not-exist")
    assert_redirected_to community_path
  end

  # ── Thread page ─────────────────────────────────────────────────────────────

  test "anonymous visitor can view a thread in an open forum" do
    get community_thread_path(@open_forum.slug, @thread)
    assert_response :ok
    assert_match @thread.title, response.body
  end

  test "view count increments on each thread visit" do
    initial = @thread.view_count
    get community_thread_path(@open_forum.slug, @thread)
    assert_equal initial + 1, @thread.reload.view_count
  end

  test "anonymous visitor is redirected from a thread in a members_only forum" do
    members_thread = build_thread("Members Thread", @members_forum, @editor)
    get community_thread_path(@members_forum.slug, members_thread)
    assert_redirected_to root_path
  end

  test "member can view a thread in a members_only forum" do
    sign_in_as @member
    members_thread = build_thread("Members Thread", @members_forum, @editor)
    get community_thread_path(@members_forum.slug, members_thread)
    assert_response :ok
  end

  # ── New thread (auth gate) ───────────────────────────────────────────────────

  test "anonymous visitor cannot reach the new thread form" do
    get new_community_thread_path(@open_forum.slug)
    assert_redirected_to new_session_path
  end

  test "authenticated member can reach the new thread form" do
    sign_in_as @member
    get new_community_thread_path(@open_forum.slug)
    assert_response :ok
    assert_match "forum_thread[title]", response.body
  end

  # ── Create thread ───────────────────────────────────────────────────────────

  test "anonymous visitor cannot post a new thread" do
    assert_no_difference "ForumThread.count" do
      post community_threads_path(@open_forum.slug), params: {
        forum_thread: { title: "Anon Thread", body: "Body" }
      }
    end
    assert_redirected_to new_session_path
  end

  test "authenticated member can create a thread" do
    sign_in_as @member
    assert_difference "ForumThread.count", 1 do
      post community_threads_path(@open_forum.slug), params: {
        forum_thread: { title: "A New Thread", body: "Thread body content." }
      }
    end
    thread = ForumThread.find_by!(title: "A New Thread")
    assert_equal @member, thread.author
    assert_equal @open_forum, thread.forum
    assert_redirected_to community_thread_path(@open_forum.slug, thread)
    follow_redirect!
    assert_match "Thread posted.", response.body
  end

  test "thread creation fails when title is blank" do
    sign_in_as @member
    assert_no_difference "ForumThread.count" do
      post community_threads_path(@open_forum.slug), params: {
        forum_thread: { title: "", body: "Some body." }
      }
    end
    assert_response :unprocessable_entity
  end

  test "thread creation fails when body is blank" do
    sign_in_as @member
    assert_no_difference "ForumThread.count" do
      post community_threads_path(@open_forum.slug), params: {
        forum_thread: { title: "No Body Thread", body: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  # ── Create reply ─────────────────────────────────────────────────────────────

  test "anonymous visitor cannot post a reply" do
    assert_no_difference "ForumReply.count" do
      post community_thread_replies_path(@open_forum.slug, @thread), params: {
        forum_reply: { body: "Anonymous reply attempt" }
      }
    end
    assert_redirected_to new_session_path
  end

  test "authenticated member can post a reply via HTML" do
    sign_in_as @member
    assert_difference "ForumReply.count", 1 do
      post community_thread_replies_path(@open_forum.slug, @thread), params: {
        forum_reply: { body: "A helpful reply." }
      }
    end
    reply = ForumReply.last
    assert_equal @member, reply.author
    assert_equal @thread,  reply.forum_thread
    assert_redirected_to community_thread_path(@open_forum.slug, @thread)
  end

  test "authenticated member can post a reply via Turbo Stream" do
    sign_in_as @member
    assert_difference "ForumReply.count", 1 do
      post community_thread_replies_path(@open_forum.slug, @thread),
           params:  { forum_reply: { body: "A turbo reply." } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end
    assert_response :ok
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    assert_match "turbo-stream", response.body
    assert_match "replies", response.body
    assert_match "reply-form", response.body
  end

  test "reply to a locked thread is rejected" do
    sign_in_as @member
    assert_no_difference "ForumReply.count" do
      post community_thread_replies_path(@open_forum.slug, @locked_thread), params: {
        forum_reply: { body: "Reply to locked thread." }
      }
    end
    # Pundit raises NotAuthorizedError → redirect with alert
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "reply counter increments after a successful reply" do
    sign_in_as @member
    assert_difference "@thread.reload.reply_count", 1 do
      post community_thread_replies_path(@open_forum.slug, @thread), params: {
        forum_reply: { body: "Counter test reply." }
      }
    end
  end

  test "reply body cannot be blank" do
    sign_in_as @member
    assert_no_difference "ForumReply.count" do
      post community_thread_replies_path(@open_forum.slug, @thread), params: {
        forum_reply: { body: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  private

  # Create a ForumThread with an Action Text body in one call.
  def build_thread(title, forum, author, locked: false, pinned: false)
    t = ForumThread.new(title: title, forum: forum, author: author,
                        locked: locked, pinned: pinned)
    t.body = "Thread body for #{title}."
    t.save!
    t
  end
end
