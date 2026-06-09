require "test_helper"

class MembersAndSettingsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "admin-ms-#{SecureRandom.hex(4)}@test.com",
      password:      "securepassword123",
      role:          :admin,
      display_name:  "AdminVybe#{SecureRandom.hex(3)}"
    )
    @author = User.create!(
      email_address: "author-ms-#{SecureRandom.hex(4)}@test.com",
      password:      "securepassword123",
      role:          :author
      # intentionally no display_name
    )
  end

  # ── GET /members/:display_name ────────────────────────────────────────────────

  test "member profile page renders for a user with a display_name" do
    get member_path(@admin.display_name)
    assert_response :ok
    assert_select "h1", text: @admin.display_name
  end

  test "member profile page returns 404 for unknown display_name" do
    get member_path("no-such-user-xyz-#{SecureRandom.hex(4)}")
    assert_response :not_found
  end

  test "member profile is accessible without signing in" do
    get member_path(@admin.display_name)
    assert_response :ok
  end

  test "member profile shows published posts by that author" do
    post = Post.create!(
      title:        "Member Post #{SecureRandom.hex(4)}",
      author:       @admin,
      status:       :published,
      published_at: 1.day.ago,
      slug:         "member-post-#{SecureRandom.hex(4)}"
    )

    get member_path(@admin.display_name)

    assert_response :ok
    assert_includes response.body, post.title
  end

  test "member profile does not show draft posts" do
    draft = Post.create!(
      title:  "Draft Only #{SecureRandom.hex(4)}",
      author: @admin,
      status: :draft,
      slug:   "draft-only-#{SecureRandom.hex(4)}"
    )

    get member_path(@admin.display_name)

    assert_not_includes response.body, draft.title
  end

  test "member profile lookup is case-insensitive" do
    get member_path(@admin.display_name.upcase)
    assert_response :ok

    get member_path(@admin.display_name.downcase)
    assert_response :ok
  end

  # ── GET /settings ─────────────────────────────────────────────────────────────

  test "settings page requires authentication" do
    get settings_path
    assert_redirected_to new_session_path
  end

  test "settings page renders for authenticated user" do
    sign_in_as @author
    get settings_path
    assert_response :ok
    assert_select "h1", text: /settings/i
  end

  test "settings page shows profile form with user email" do
    sign_in_as @admin
    get settings_path
    assert_response :ok
    assert_select "input[name='user[email_address]']"
  end

  test "settings page shows password change form" do
    sign_in_as @author
    get settings_path
    assert_response :ok
    assert_select "input[name='current_password']"
    assert_select "input[name='password']"
    assert_select "input[name='password_confirmation']"
  end

  # ── PATCH /settings ───────────────────────────────────────────────────────────

  test "update saves display_name and bio" do
    sign_in_as @author

    patch settings_path, params: {
      user: {
        email_address: @author.email_address,
        display_name:  "freshname#{SecureRandom.hex(3)}",
        bio:           "I write music reviews.",
        website_url:   ""
      }
    }

    assert_redirected_to settings_path
    @author.reload
    assert_equal "I write music reviews.", @author.bio
  end

  test "update saves valid website_url" do
    sign_in_as @author

    patch settings_path, params: {
      user: {
        email_address: @author.email_address,
        website_url:   "https://example.com"
      }
    }

    assert_redirected_to settings_path
    assert_equal "https://example.com", @author.reload.website_url
  end

  test "update rejects invalid website_url" do
    sign_in_as @author

    patch settings_path, params: {
      user: {
        email_address: @author.email_address,
        website_url:   "not-a-url"
      }
    }

    assert_response :unprocessable_entity
    @author.reload
    assert_nil @author.website_url
  end

  test "update rejects bio over 280 characters" do
    sign_in_as @author

    patch settings_path, params: {
      user: {
        email_address: @author.email_address,
        bio:           "x" * 281
      }
    }

    assert_response :unprocessable_entity
  end

  test "update rejects duplicate display_name" do
    sign_in_as @author

    patch settings_path, params: {
      user: {
        email_address: @author.email_address,
        display_name:  @admin.display_name.downcase
      }
    }

    assert_response :unprocessable_entity
  end

  test "update without authentication redirects to sign in" do
    patch settings_path, params: { user: { bio: "hacker" } }
    assert_redirected_to new_session_path
  end

  # ── PATCH /settings/update_password ──────────────────────────────────────────

  test "update_password succeeds with correct current password" do
    sign_in_as @author

    patch update_password_settings_path, params: {
      current_password:      "securepassword123",
      password:              "newpassword456789",
      password_confirmation: "newpassword456789"
    }

    assert_redirected_to settings_path
    follow_redirect!
    assert_match(/password updated/i, flash[:notice])
  end

  test "update_password fails with wrong current password" do
    sign_in_as @author

    patch update_password_settings_path, params: {
      current_password:      "wrongpassword",
      password:              "newpassword456789",
      password_confirmation: "newpassword456789"
    }

    assert_redirected_to settings_path
    follow_redirect!
    assert_match(/incorrect/i, flash[:alert])
  end

  test "update_password fails when confirmation does not match" do
    sign_in_as @author

    patch update_password_settings_path, params: {
      current_password:      "securepassword123",
      password:              "newpassword456789",
      password_confirmation: "differentpassword"
    }

    assert_redirected_to settings_path
    follow_redirect!
    assert_match(/do not match/i, flash[:alert])
  end

  test "update_password fails when new password is too short" do
    sign_in_as @author

    patch update_password_settings_path, params: {
      current_password:      "securepassword123",
      password:              "short",
      password_confirmation: "short"
    }

    assert_redirected_to settings_path
    follow_redirect!
    assert_match(/at least 12/i, flash[:alert])
  end

  test "update_password requires authentication" do
    patch update_password_settings_path, params: {
      current_password:      "securepassword123",
      password:              "newpassword456789",
      password_confirmation: "newpassword456789"
    }
    assert_redirected_to new_session_path
  end
end
