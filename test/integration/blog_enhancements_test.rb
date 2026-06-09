require "test_helper"

# Integration tests for Phase 1.5 blog enhancements:
# reading time display, related posts, draft preview (via PostPolicy),
# RSS feed, and post series pages.
class BlogEnhancementsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "admin-blog-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :admin
    )
    @author = User.create!(
      email_address: "author-blog-#{SecureRandom.hex(4)}@test.com",
      password:      "password",
      role:          :author
    )

    @category = Category.create!(name: "Tech #{SecureRandom.hex(4)}")

    @published_post = Post.create!(
      title:        "Published Post #{SecureRandom.hex(4)}",
      author:       @admin,
      status:       :published,
      published_at: 1.day.ago,
      slug:         "published-#{SecureRandom.hex(4)}"
    )
    @published_post.categories << @category

    @draft_post = Post.create!(
      title:  "Draft Post #{SecureRandom.hex(4)}",
      author: @author,
      status: :draft,
      slug:   "draft-#{SecureRandom.hex(4)}"
    )
    @draft_post.categories << @category
  end

  # ── reading time ─────────────────────────────────────────────────────────────

  test "post show page displays reading time in byline" do
    get post_path(@published_post)
    assert_response :ok
    # assert_select gives decoded text (entities + &nbsp; resolved)
    assert_select "p.byline" do |bylines|
      assert_match(/\d+.*min.*read/i, bylines.first.inner_text)
    end
  end

  # ── related posts ────────────────────────────────────────────────────────────

  test "related posts section appears when category overlap exists" do
    related = Post.create!(
      title:        "Related Post #{SecureRandom.hex(4)}",
      author:       @admin,
      status:       :published,
      published_at: 2.days.ago,
      slug:         "related-#{SecureRandom.hex(4)}"
    )
    related.categories << @category

    get post_path(@published_post)

    assert_response :ok
    assert_select ".post-grid--compact"
    assert_select "h2 a", text: related.title
  end

  test "related posts section absent when no category overlap" do
    # published_post has @category; create a post with a different category
    other_cat = Category.create!(name: "Other #{SecureRandom.hex(4)}")
    solo_post = Post.create!(
      title:        "Solo Post #{SecureRandom.hex(4)}",
      author:       @admin,
      status:       :published,
      published_at: 1.day.ago,
      slug:         "solo-#{SecureRandom.hex(4)}"
    )
    solo_post.categories << other_cat

    get post_path(solo_post)

    assert_response :ok
    assert_select ".post-grid--compact", count: 0
  end

  # ── draft preview ────────────────────────────────────────────────────────────

  test "draft post is hidden from guests" do
    get post_path(@draft_post)
    assert_response :not_found
  end

  test "draft post author can view their own draft" do
    sign_in_as @author
    get post_path(@draft_post)
    assert_response :ok
    assert_select "h1", text: @draft_post.title
  end

  test "admin can view any draft post" do
    sign_in_as @admin
    get post_path(@draft_post)
    assert_response :ok
  end

  # ── RSS feed ─────────────────────────────────────────────────────────────────

  test "feed.xml returns 200" do
    get feed_path(format: :xml)
    assert_response :ok
  end

  test "feed.xml returns XML content type" do
    get feed_path(format: :xml)
    assert_includes response.content_type, "application/xml"
  end

  test "feed.xml includes published posts" do
    get feed_path(format: :xml)
    assert_includes response.body, @published_post.title
  end

  test "feed.xml does not include draft posts" do
    get feed_path(format: :xml)
    assert_not_includes response.body, @draft_post.title
  end

  test "feed.xml contains RSS channel element" do
    get feed_path(format: :xml)
    assert_includes response.body, "<rss"
    assert_includes response.body, "<channel>"
    assert_includes response.body, "<item>"
  end

  # ── series pages ─────────────────────────────────────────────────────────────

  test "series show page renders published posts in the series" do
    series = Series.create!(title: "Test Series #{SecureRandom.hex(4)}")
    @published_post.update!(series: series, series_position: 1)

    get series_path(series)

    assert_response :ok
    assert_select "h1", text: series.title
    assert_select ".series-list__item"
    assert_select "h2 a", text: @published_post.title
  end

  test "series show page returns 404 for unknown slug" do
    get series_path("no-such-series-xyz")
    assert_response :not_found
  end

  test "series show page displays post count" do
    series = Series.create!(title: "Count Series #{SecureRandom.hex(4)}")
    @published_post.update!(series: series, series_position: 1)

    get series_path(series)

    assert_response :ok
    assert_match(/1\s+post/i, response.body)
  end

  test "series show page displays series description when present" do
    series = Series.create!(
      title:       "With Desc #{SecureRandom.hex(4)}",
      description: "A detailed series description."
    )

    get series_path(series)

    assert_response :ok
    assert_includes response.body, "A detailed series description."
  end

  test "post show page shows series badge when post belongs to series" do
    series = Series.create!(title: "My Series #{SecureRandom.hex(4)}")
    @published_post.update!(series: series, series_position: 2)

    get post_path(@published_post)

    assert_response :ok
    assert_select ".series-badge"
    assert_select ".series-badge a", text: series.title
  end

  test "post show page has no series badge when not in a series" do
    get post_path(@published_post)
    # @published_post has no series in default setup
    assert_select ".series-badge", count: 0
  end
end
