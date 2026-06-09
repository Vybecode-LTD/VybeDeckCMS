require "test_helper"

class PostTest < ActiveSupport::TestCase
  setup do
    @author = User.create!(
      email_address: "author-post-#{SecureRandom.hex(4)}@test.com",
      password:      "password"
    )
  end

  def build_post(overrides = {})
    Post.new({ title: "Test Post", author: @author }.merge(overrides))
  end

  # ── reading_time ─────────────────────────────────────────────────────────────

  test "reading_time returns 1 for empty body" do
    post = build_post
    assert_equal 1, post.reading_time
  end

  test "reading_time returns 1 for a very short body" do
    post = build_post
    post.body = "Short content."
    assert_equal 1, post.reading_time
  end

  test "reading_time rounds up to nearest minute" do
    post = build_post
    # 201 words → (201/200.0).ceil = 2
    post.body = (["word"] * 201).join(" ")
    assert_equal 2, post.reading_time
  end

  test "reading_time returns 1 for exactly 200 words" do
    post = build_post
    post.body = (["word"] * 200).join(" ")
    assert_equal 1, post.reading_time
  end

  # ── series association ────────────────────────────────────────────────────────

  test "post can belong to a series" do
    series = Series.create!(title: "Test Series #{SecureRandom.hex(4)}")
    post   = build_post
    post.series = series
    post.series_position = 1
    assert_equal series, post.series
    assert_equal 1, post.series_position
  end

  test "post is valid without a series" do
    post = build_post
    assert post.valid?, post.errors.full_messages.inspect
    assert_nil post.series
  end
end
