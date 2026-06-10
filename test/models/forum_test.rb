require "test_helper"

# Forum model tests — Phase 4.5 colour_hex validation.
class ForumTest < ActiveSupport::TestCase
  def valid_forum(overrides = {})
    Forum.new({ name: "Test Forum #{SecureRandom.hex(4)}", visibility: :open, position: 0 }.merge(overrides))
  end

  test "valid forum with no colour_hex" do
    assert valid_forum.valid?
  end

  test "valid forum with valid hex colour" do
    assert valid_forum(colour_hex: "#e8440a").valid?
    assert valid_forum(colour_hex: "#FFFFFF").valid?
    assert valid_forum(colour_hex: "#000000").valid?
  end

  test "invalid forum with malformed colour_hex — missing hash" do
    f = valid_forum(colour_hex: "e8440a")
    assert_not f.valid?
    assert_match "6-digit hex colour", f.errors[:colour_hex].join
  end

  test "invalid forum with short hex" do
    f = valid_forum(colour_hex: "#fff")
    assert_not f.valid?
  end

  test "invalid forum with non-hex characters" do
    f = valid_forum(colour_hex: "#zzzzzz")
    assert_not f.valid?
  end

  test "blank colour_hex is valid (no accent override)" do
    assert valid_forum(colour_hex: "").valid?
    assert valid_forum(colour_hex: nil).valid?
  end
end
