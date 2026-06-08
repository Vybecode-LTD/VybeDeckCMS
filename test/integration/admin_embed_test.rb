require "test_helper"

# Integration tests for the admin embed preview endpoint.
class AdminEmbedTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "admin-embed-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :admin
    )
    @editor = User.create!(
      email_address: "editor-embed-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :editor
    )
    @author = User.create!(
      email_address: "author-embed-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :author
    )
  end

  # ── access control ──────────────────────────────────────────────────────────

  test "admin can access embed preview" do
    sign_in_as @admin
    get admin_embed_preview_path, params: { url: "https://youtu.be/dQw4w9WgXcQ" }
    assert_response :ok
  end

  test "editor can access embed preview" do
    sign_in_as @editor
    get admin_embed_preview_path, params: { url: "https://youtu.be/dQw4w9WgXcQ" }
    assert_response :ok
  end

  test "author is forbidden from embed preview" do
    sign_in_as @author
    get admin_embed_preview_path, params: { url: "https://youtu.be/dQw4w9WgXcQ" }
    assert_response :redirect # Pundit redirects unauthorised users
  end

  test "guest is redirected from embed preview" do
    get admin_embed_preview_path, params: { url: "https://youtu.be/dQw4w9WgXcQ" }
    assert_response :redirect
  end

  # ── successful previews ─────────────────────────────────────────────────────

  test "returns iframe for youtube URL" do
    sign_in_as @admin
    get admin_embed_preview_path, params: { url: "https://youtu.be/dQw4w9WgXcQ" }
    assert_response :ok
    assert_select "iframe[src*='youtube.com/embed']"
    assert_select ".embed-widget--youtube"
  end

  test "returns iframe for vimeo URL" do
    sign_in_as @admin
    get admin_embed_preview_path, params: { url: "https://vimeo.com/76979871" }
    assert_response :ok
    assert_select "iframe[src*='player.vimeo.com']"
  end

  test "returns iframe for spotify URL" do
    sign_in_as @admin
    get admin_embed_preview_path,
        params: { url: "https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh" }
    assert_response :ok
    assert_select "iframe[src*='open.spotify.com/embed']"
  end

  test "returns iframe for soundcloud URL" do
    sign_in_as @admin
    get admin_embed_preview_path,
        params: { url: "https://soundcloud.com/artist/track" }
    assert_response :ok
    assert_select "iframe[src*='w.soundcloud.com']"
  end

  test "returns iframe for apple music URL" do
    sign_in_as @admin
    get admin_embed_preview_path,
        params: { url: "https://music.apple.com/us/album/folklore/1528112358" }
    assert_response :ok
    assert_select "iframe[src*='embed.music.apple.com']"
  end

  # ── unrecognised URL ────────────────────────────────────────────────────────

  test "returns 422 for unrecognised URL" do
    sign_in_as @admin
    get admin_embed_preview_path, params: { url: "https://example.com/not-embeddable" }
    assert_response :unprocessable_entity
  end

  test "returns 422 for blank URL" do
    sign_in_as @admin
    get admin_embed_preview_path, params: { url: "" }
    assert_response :unprocessable_entity
  end
end
