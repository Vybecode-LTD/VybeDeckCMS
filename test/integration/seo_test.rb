require "test_helper"

class SeoTest < ActionDispatch::IntegrationTest
  def setup
    @author = User.create!(
      email_address:   "seo_author_#{SecureRandom.hex(4)}@test.com",
      password:        "password1234",
      display_name:    "SeoAuthor#{SecureRandom.hex(4)}",
      role:            :author,
      email_verified_at: Time.current
    )
    @post = Post.create!(
      title:      "SEO Test Post",
      slug:       "seo-test-post-#{SecureRandom.hex(4)}",
      status:     :published,
      published_at: 1.day.ago,
      author:     @author,
      meta_title: "Custom SEO Title",
      meta_description: "Custom SEO description for the post."
    )
    @page = Page.create!(
      title:  "SEO Test Page",
      slug:   "seo-test-page-#{SecureRandom.hex(4)}",
      status: :published
    )
  end

  # ── Meta tags in layout ────────────────────────────────────────────────────

  test "blog index has og:site_name" do
    get posts_path
    assert_response :success
    assert_match 'og:site_name', response.body
    assert_match 'VybeDeck CMS', response.body
  end

  test "blog index has canonical link" do
    get posts_path
    assert_response :success
    assert_match 'rel="canonical"', response.body
  end

  test "blog index has twitter:card meta" do
    get posts_path
    assert_response :success
    assert_match 'twitter:card', response.body
    assert_match 'summary_large_image', response.body
  end

  test "post show has og:type article" do
    get post_path(@post)
    assert_response :success
    assert_match 'og:type', response.body
    assert_match '"article"', response.body
  end

  test "post show has og:title from meta_title" do
    get post_path(@post)
    assert_response :success
    assert_match 'og:title', response.body
    assert_match 'Custom SEO Title', response.body
  end

  test "post show has og:description" do
    get post_path(@post)
    assert_response :success
    assert_match 'og:description', response.body
    assert_match 'Custom SEO description', response.body
  end

  test "post show has JSON-LD article schema" do
    get post_path(@post)
    assert_response :success
    assert_match 'application/ld+json', response.body
    assert_match '"@type": "Article"', response.body
    assert_match @author.display_name, response.body
  end

  # ── sitemap.xml ───────────────────────────────────────────────────────────

  test "sitemap returns XML" do
    get sitemap_path
    assert_response :success
    assert_equal "application/xml", response.content_type.split(";").first
  end

  test "sitemap includes root URL" do
    get sitemap_path
    assert_match "<urlset", response.body
    assert_match root_url, response.body
  end

  test "sitemap includes published post" do
    get sitemap_path
    assert_match post_url(@post), response.body
  end

  test "sitemap does not include draft post" do
    draft = Post.create!(
      title: "Draft", slug: "draft-seo-#{SecureRandom.hex(4)}",
      status: :draft, author: @author
    )
    get sitemap_path
    assert_no_match post_url(draft), response.body
  end

  # ── robots.txt ────────────────────────────────────────────────────────────

  test "robots.txt returns text/plain" do
    get robots_txt_path
    assert_response :success
    assert_equal "text/plain", response.content_type.split(";").first
  end

  test "robots.txt disallows /admin/" do
    get robots_txt_path
    assert_match "Disallow: /admin/", response.body
  end

  test "robots.txt includes sitemap URL" do
    get robots_txt_path
    assert_match "Sitemap:", response.body
    assert_match "sitemap.xml", response.body
  end

  test "robots.txt includes custom rules from site settings" do
    SiteSetting.set("robots_txt_custom", "Disallow: /private/")
    get robots_txt_path
    assert_match "Disallow: /private/", response.body
  ensure
    SiteSetting.set("robots_txt_custom", "")
  end
end
