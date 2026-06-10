require "test_helper"

class AdminAlbumsTest < ActionDispatch::IntegrationTest
  def setup
    @admin  = create_user(role: :admin)
    @editor = create_user(role: :editor)
    @member = create_user(role: :member)
  end

  # ── Helpers ────────────────────────────────────────────────────────────────

  def create_user(role:)
    User.create!(
      email_address: "#{role}_#{SecureRandom.hex(4)}@test.com",
      password: "password1234",
      display_name: "#{role.to_s.capitalize}#{SecureRandom.hex(4)}",
      role: role,
      email_verified_at: Time.current
    )
  end

  def create_album(attrs = {})
    Album.create!({ title: "Album #{SecureRandom.hex(4)}" }.merge(attrs))
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  # ── Auth gates ─────────────────────────────────────────────────────────────

  test "anonymous is redirected to login" do
    get admin_albums_path
    assert_redirected_to new_session_path
  end

  test "member cannot access admin albums" do
    sign_in @member
    get admin_albums_path
    assert_redirected_to root_path
  end

  test "editor can access admin albums index" do
    sign_in @editor
    get admin_albums_path
    assert_response :success
  end

  test "admin can access admin albums index" do
    sign_in @admin
    get admin_albums_path
    assert_response :success
  end

  # ── CRUD ──────────────────────────────────────────────────────────────────

  test "admin can create an album" do
    sign_in @admin
    assert_difference "Album.count", 1 do
      post admin_albums_path, params: { album: { title: "New Release" } }
    end
    assert_redirected_to admin_album_path(Album.last)
  end

  test "editor can create an album" do
    sign_in @editor
    assert_difference "Album.count", 1 do
      post admin_albums_path, params: { album: { title: "Editor Album" } }
    end
    assert_response :redirect
  end

  test "create with blank title re-renders form" do
    sign_in @admin
    assert_no_difference "Album.count" do
      post admin_albums_path, params: { album: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "admin can update an album" do
    sign_in @admin
    album = create_album
    patch admin_album_path(album), params: { album: { title: "Updated Title" } }
    album.reload
    assert_redirected_to admin_album_path(album)
    assert_equal "Updated Title", album.title
  end

  test "admin can delete an album" do
    sign_in @admin
    album = create_album
    assert_difference "Album.count", -1 do
      delete admin_album_path(album)
    end
    assert_redirected_to admin_albums_path
  end

  test "editor cannot delete an album" do
    sign_in @editor
    album = create_album
    assert_no_difference "Album.count" do
      delete admin_album_path(album)
    end
    assert_redirected_to root_path
  end

  # ── Publish pipeline ───────────────────────────────────────────────────────

  test "publish action without release_date redirects with alert" do
    sign_in @admin
    album = create_album
    patch publish_admin_album_path(album)
    assert_redirected_to admin_album_path(album)
    assert_not_nil flash[:alert]
  end

  test "editor cannot publish" do
    sign_in @editor
    album = create_album
    patch publish_admin_album_path(album)
    assert_redirected_to root_path
  end

  # ── Track management ───────────────────────────────────────────────────────

  test "admin can create a track" do
    sign_in @admin
    album = create_album
    assert_difference "Track.count", 1 do
      post admin_album_tracks_path(album), params: { track: { title: "Track One" } }
    end
    assert_response :redirect
  end

  test "reorder endpoint updates positions" do
    sign_in @admin
    album  = create_album
    t1 = album.tracks.create!(title: "T1", position: 1)
    t2 = album.tracks.create!(title: "T2", position: 2)
    patch reorder_admin_album_tracks_path(album), params: { positions: [ t2.id, t1.id ] }
    assert_response :ok
    assert_equal 0, t2.reload.position
    assert_equal 1, t1.reload.position
  end

  # ── Download report ────────────────────────────────────────────────────────

  test "admin can see download report" do
    sign_in @admin
    get admin_album_download_report_path
    assert_response :success
  end

  test "member cannot see download report" do
    sign_in @member
    get admin_album_download_report_path
    assert_redirected_to root_path
  end
end
