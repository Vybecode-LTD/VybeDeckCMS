require "test_helper"

class PublicAlbumsTest < ActionDispatch::IntegrationTest
  def create_user(role: :member)
    User.create!(
      email_address: "#{role}_#{SecureRandom.hex(4)}@test.com",
      password: "password1234",
      display_name: "User#{SecureRandom.hex(4)}",
      role: role,
      email_verified_at: Time.current
    )
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: "password1234" }
  end

  test "public albums index is accessible to anonymous" do
    get albums_path
    assert_response :success
  end

  test "public albums index shows published albums" do
    Album.create!(title: "Published One", status: :published)
    Album.create!(title: "Draft Hidden",  status: :draft)
    get albums_path
    assert_match "Published One", response.body
    assert_no_match "Draft Hidden", response.body
  end

  test "public album show is accessible for published album" do
    album = Album.create!(title: "Show Me", status: :published)
    get album_path(slug: album.slug)
    assert_response :success
    assert_match "Show Me", response.body
  end

  test "published album show renders track list" do
    album  = Album.create!(title: "Full LP", status: :published)
    album.tracks.create!(title: "Track Alpha", position: 1)
    album.tracks.create!(title: "Track Beta",  position: 2)
    get album_path(slug: album.slug)
    assert_response :success
    assert_match "Track Alpha", response.body
    assert_match "Track Beta",  response.body
  end

  test "draft album show returns 404" do
    album = Album.create!(title: "Secret Draft", status: :draft)
    get album_path(slug: album.slug)
    assert_response :not_found
  end
end
