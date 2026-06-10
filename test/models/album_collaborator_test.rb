require "test_helper"

class AlbumCollaboratorTest < ActiveSupport::TestCase
  def create_album
    Album.create!(title: "Album #{SecureRandom.hex(4)}")
  end

  def create_user(role: :author)
    User.create!(
      email_address: "user_#{SecureRandom.hex(4)}@test.com",
      password: "password1234",
      display_name: "User#{SecureRandom.hex(4)}",
      role: role,
      email_verified_at: Time.current
    )
  end

  test "valid collaborator" do
    ac = AlbumCollaborator.new(album: create_album, user: create_user, role: :producer)
    assert ac.valid?
  end

  test "requires album" do
    ac = AlbumCollaborator.new(user: create_user, role: :producer)
    assert_not ac.valid?
  end

  test "requires user" do
    ac = AlbumCollaborator.new(album: create_album, role: :producer)
    assert_not ac.valid?
  end

  test "defaults role to producer when unset" do
    ac = AlbumCollaborator.new(album: create_album, user: create_user)
    assert ac.valid?
    assert_predicate ac, :producer?
  end

  test "unique user per album" do
    album = create_album
    user  = create_user
    AlbumCollaborator.create!(album: album, user: user, role: :producer)
    dup = AlbumCollaborator.new(album: album, user: user, role: :engineer)
    assert_not dup.valid?
  end

  test "same user can collaborate on different albums" do
    user   = create_user
    album1 = create_album
    album2 = create_album
    AlbumCollaborator.create!(album: album1, user: user, role: :artist)
    ac2 = AlbumCollaborator.new(album: album2, user: user, role: :artist)
    assert ac2.valid?
  end

  test "role enum values" do
    %w[producer engineer artist manager].each do |r|
      ac = AlbumCollaborator.new(album: create_album, user: create_user, role: r)
      assert ac.valid?, "Expected #{r} to be valid"
    end
  end
end
