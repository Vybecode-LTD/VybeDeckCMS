require "test_helper"

class AlbumTest < ActiveSupport::TestCase
  def build_album(overrides = {})
    Album.new({ title: "Test Album #{SecureRandom.hex(4)}" }.merge(overrides))
  end

  test "valid album" do
    assert build_album.valid?
  end

  test "requires title" do
    a = build_album(title: "")
    assert_not a.valid?
  end

  test "default status is draft" do
    assert build_album.draft?
  end

  test "status enum values" do
    %w[draft in_review mastered published].each do |s|
      a = build_album(status: s)
      assert a.valid?, "Expected #{s} to be valid"
    end
  end

  test "publish! fails without artwork" do
    a = build_album
    a.save!
    a.tracks.create!(title: "Track 1", position: 0)
    a.update!(release_date: 1.month.from_now)
    result = a.publish!
    assert_not result
    assert a.errors[:base].any? { |e| e.include?("Artwork") }
  end

  test "publish! fails without release_date" do
    a = build_album
    a.save!
    result = a.publish!
    assert_not result
    assert a.errors[:base].any? { |e| e.include?("Release date") }
  end

  test "publish! fails without any track with audio" do
    a = build_album
    a.save!
    a.update!(release_date: 1.month.from_now)
    # no track with audio
    result = a.publish!
    assert_not result
    assert a.errors[:base].any? { |e| e.include?("track") }
  end

  test "published scope" do
    a = build_album(status: :published)
    a.save!
    assert_includes Album.published, a
    assert_not_includes Album.published, build_album(status: :draft).tap(&:save!)
  end

  test "FriendlyId generates slug from title" do
    a = build_album(title: "My Great Album")
    a.save!
    assert_match(/my-great-album/, a.slug)
  end
end
