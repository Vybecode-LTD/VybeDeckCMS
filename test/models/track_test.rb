require "test_helper"

class TrackTest < ActiveSupport::TestCase
  def create_album
    Album.create!(title: "Album #{SecureRandom.hex(4)}")
  end

  test "valid track" do
    album = create_album
    t = Track.new(title: "Track One", album: album)
    assert t.valid?
  end

  test "requires title" do
    album = create_album
    t = Track.new(title: "", album: album)
    assert_not t.valid?
  end

  test "requires album" do
    t = Track.new(title: "Orphan Track")
    assert_not t.valid?
  end

  test "auto-assigns position starting at zero" do
    album = create_album
    t = Track.create!(title: "First", album: album)
    assert_equal 0, t.position
  end

  test "auto-assigns incrementing positions" do
    album = create_album
    t1 = Track.create!(title: "First",  album: album)
    t2 = Track.create!(title: "Second", album: album)
    assert_equal 0, t1.position
    assert_equal 1, t2.position
  end

  test "tracks ordered by position" do
    album = create_album
    t1 = album.tracks.create!(title: "A")  # auto-gets position 0
    t2 = album.tracks.create!(title: "B")  # auto-gets position 1
    assert_equal [t1, t2], album.tracks.reload.to_a
  end
end
