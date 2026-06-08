require "test_helper"

class AdminMediaTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "admin-media-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :admin
    )
    @editor = User.create!(
      email_address: "editor-media-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :editor
    )
    @author = User.create!(
      email_address: "author-media-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :author
    )
  end

  def png_upload(filename: "photo.png", title: "")
    file = Rack::Test::UploadedFile.new(
      StringIO.new("\x89PNG\r\n\x1a\n" + ("x" * 100)),
      "image/png",
      original_filename: filename
    )
    { medium: { file: file, title: title } }
  end

  # ── access control ──────────────────────────────────────────────────────────

  test "admin can access media library" do
    sign_in_as @admin
    get admin_media_path
    assert_response :success
  end

  test "editor can access media library" do
    sign_in_as @editor
    get admin_media_path
    assert_response :success
  end

  test "author is redirected from media library" do
    sign_in_as @author
    get admin_media_path
    assert_redirected_to root_path
  end

  test "guest is redirected from media library" do
    get admin_media_path
    assert_redirected_to new_session_path
  end

  # ── upload ───────────────────────────────────────────────────────────────────

  test "admin can upload an image" do
    sign_in_as @admin
    assert_difference "Medium.count", 1 do
      post admin_media_path, params: png_upload(title: "My Photo")
    end
    assert_redirected_to admin_media_path
    medium = Medium.last
    assert_equal "My Photo", medium.title
    assert_equal "image",    medium.file_type
    assert medium.file.attached?
  end

  test "title is auto-set from filename when blank" do
    sign_in_as @admin
    post admin_media_path, params: png_upload(filename: "hero_banner.png", title: "")
    assert_equal "Hero banner", Medium.last.title
  end

  test "file_type is auto-inferred from content type" do
    sign_in_as @admin
    file = Rack::Test::UploadedFile.new(
      StringIO.new("ID3"),
      "audio/mpeg",
      original_filename: "track.mp3"
    )
    post admin_media_path, params: { medium: { file: file, title: "Track" } }
    assert_equal "audio", Medium.last.file_type
  end

  test "upload fails with unsupported content type" do
    sign_in_as @admin
    file = Rack::Test::UploadedFile.new(
      StringIO.new("data"),
      "application/octet-stream",
      original_filename: "bad.exe"
    )
    assert_no_difference "Medium.count" do
      post admin_media_path, params: { medium: { file: file, title: "Bad" } }
    end
    assert_response :unprocessable_entity
  end

  # ── show ─────────────────────────────────────────────────────────────────────

  test "admin can view a medium" do
    sign_in_as @admin
    medium = create_medium
    get admin_medium_path(medium)
    assert_response :success
    assert_select "h1", text: medium.title
  end

  # ── edit / update ────────────────────────────────────────────────────────────

  test "admin can update title and alt text" do
    sign_in_as @admin
    medium = create_medium(title: "Old title")
    patch admin_medium_path(medium), params: { medium: { title: "New title", alt_text: "A photo" } }
    assert_redirected_to admin_medium_path(medium)
    assert_equal "New title", medium.reload.title
    assert_equal "A photo",   medium.alt_text
  end

  # ── destroy ──────────────────────────────────────────────────────────────────

  test "admin can delete a medium" do
    sign_in_as @admin
    medium = create_medium
    assert_difference "Medium.count", -1 do
      delete admin_medium_path(medium)
    end
    assert_redirected_to admin_media_path
  end

  # ── bulk destroy ─────────────────────────────────────────────────────────────

  test "admin can bulk-delete media" do
    sign_in_as @admin
    m1 = create_medium(title: "One")
    m2 = create_medium(title: "Two")
    assert_difference "Medium.count", -2 do
      delete bulk_destroy_admin_media_path, params: { medium_ids: [m1.id, m2.id] }
    end
    assert_redirected_to admin_media_path
  end

  # ── filter ───────────────────────────────────────────────────────────────────

  test "filter by image type returns 200" do
    sign_in_as @admin
    get admin_media_path(filter: "image")
    assert_response :success
  end

  test "search by title returns 200" do
    sign_in_as @admin
    get admin_media_path(search: "photo")
    assert_response :success
  end

  # ── new form ─────────────────────────────────────────────────────────────────

  test "admin can view upload form" do
    sign_in_as @admin
    get new_admin_medium_path
    assert_response :success
  end

  private

  def create_medium(title: "Test file")
    m = Medium.new(title: title, uploaded_by: @admin)
    m.file.attach(
      io:           StringIO.new("\x89PNG\r\n\x1a\n" + ("x" * 100)),
      filename:     "test.png",
      content_type: "image/png"
    )
    m.save!
    m
  end
end
