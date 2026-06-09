require "test_helper"

# Tests that member and subscriber roles have exactly the right access:
# - Can sign in, manage their profile, view public content.
# - Cannot access admin, create posts, or view subscriber-gated content (member only).
class MemberAccessTest < ActionDispatch::IntegrationTest
  setup do
    @member = User.create!(
      email_address:     "member-#{SecureRandom.hex(4)}@test.com",
      password:          "securepassword123",
      role:              :member,
      email_verified_at: Time.current
    )
    @subscriber = User.create!(
      email_address:     "subscriber-#{SecureRandom.hex(4)}@test.com",
      password:          "securepassword123",
      role:              :subscriber,
      email_verified_at: Time.current
    )
    @author = User.create!(
      email_address:     "author-#{SecureRandom.hex(4)}@test.com",
      password:          "securepassword123",
      role:              :author,
      email_verified_at: Time.current
    )

    @public_post = Post.create!(
      title:               "MemberTest Public Post #{SecureRandom.hex(4)}",
      status:              :published,
      published_at:        1.day.ago,
      requires_subscriber: false,
      author:              @author,
      body:                "hello"
    )
    @gated_post = Post.create!(
      title:               "MemberTest Gated Post #{SecureRandom.hex(4)}",
      status:              :published,
      published_at:        1.day.ago,
      requires_subscriber: true,
      author:              @author,
      body:                "secret"
    )
  end

  # ── Admin access ─────────────────────────────────────────────────────────────

  test "member is redirected away from admin" do
    sign_in_as @member
    get admin_root_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to access the admin.", flash[:alert]
  end

  test "subscriber is redirected away from admin" do
    sign_in_as @subscriber
    get admin_root_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to access the admin.", flash[:alert]
  end

  # ── Profile / settings access ─────────────────────────────────────────────

  test "member can view their settings page" do
    sign_in_as @member
    get settings_path
    assert_response :ok
  end

  test "subscriber can view their settings page" do
    sign_in_as @subscriber
    get settings_path
    assert_response :ok
  end

  # ── Public post access ────────────────────────────────────────────────────

  test "member can view an ordinary published post" do
    sign_in_as @member
    get post_path(@public_post)
    assert_response :ok
  end

  test "subscriber can view an ordinary published post" do
    sign_in_as @subscriber
    get post_path(@public_post)
    assert_response :ok
  end

  test "anonymous visitor can view an ordinary published post" do
    get post_path(@public_post)
    assert_response :ok
  end

  # ── Subscriber-gated post access ─────────────────────────────────────────
  # Gated posts are excluded from policy_scope for non-subscribers, so the
  # controller's friendly_find raises RecordNotFound → 404.

  test "subscriber can view a subscriber-gated post" do
    sign_in_as @subscriber
    get post_path(@gated_post)
    assert_response :ok
  end

  test "member receives 404 for a subscriber-gated post" do
    sign_in_as @member
    get post_path(@gated_post)
    assert_response :not_found
  end

  test "anonymous visitor receives 404 for a subscriber-gated post" do
    get post_path(@gated_post)
    assert_response :not_found
  end

  test "author of other posts receives 404 for a subscriber-gated post" do
    other_author = User.create!(
      email_address: "other-#{SecureRandom.hex(4)}@test.com",
      password:      "securepassword123",
      role:          :author
    )
    sign_in_as other_author
    get post_path(@gated_post)
    assert_response :not_found
  end

  test "gated post's own author can always view it" do
    sign_in_as @author
    get post_path(@gated_post)
    assert_response :ok
  end

  # ── Post index scope — gated posts hidden from non-subscribers ───────────

  test "member does not see subscriber-gated posts in the blog index" do
    sign_in_as @member
    get posts_path
    assert_response :ok
    assert_no_match @gated_post.title, response.body
  end

  test "subscriber sees subscriber-gated posts in the blog index" do
    sign_in_as @subscriber
    get posts_path
    assert_response :ok
    assert_match @gated_post.title, response.body
  end

  # ── Pundit policy: member/subscriber cannot create posts ─────────────────

  test "PostPolicy#create? is false for member" do
    policy = PostPolicy.new(@member, Post.new)
    assert_not policy.create?, "member should not be able to create posts"
  end

  test "PostPolicy#create? is false for subscriber" do
    policy = PostPolicy.new(@subscriber, Post.new)
    assert_not policy.create?, "subscriber should not be able to create posts"
  end

  test "PostPolicy#create? is true for author" do
    policy = PostPolicy.new(@author, Post.new)
    assert policy.create?, "author should be able to create posts"
  end

  # ── Sign-in gate still applies to member/subscriber ───────────────────────

  test "member with verified email can sign in through the sessions controller" do
    post session_path, params: {
      email_address: @member.email_address,
      password:      "securepassword123"
    }
    assert_redirected_to root_path
  end

  test "subscriber with verified email can sign in through the sessions controller" do
    post session_path, params: {
      email_address: @subscriber.email_address,
      password:      "securepassword123"
    }
    assert_redirected_to root_path
  end

  # ── Role cannot be escalated via the settings profile form ───────────────

  test "member cannot escalate their own role via a settings patch" do
    sign_in_as @member
    # role is not a permitted param in SettingsController#profile_params
    patch settings_path, params: { user: { role: "admin" } }
    @member.reload
    assert @member.member?, "member should still be member after patch, got: #{@member.role}"
  end
end
