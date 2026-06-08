require "test_helper"

class PublicCmsRoutesTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email_address: "admin-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :admin
    )

    @author = User.create!(
      email_address: "author-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :author
    )
  end

  test "published page is visible to anonymous visitor" do
    page = Page.create!(
      title: "Published Page",
      status: :published,
      published_at: 1.hour.ago
    )

    get page_path(page)

    assert_response :success
    assert_equal "Published Page", response.body
  end

  test "draft page is not visible to anonymous visitor" do
    page = Page.create!(title: "Draft Page", status: :draft)

    get page_path(page)

    assert_response :not_found
  end

  test "draft page is visible to signed-in admin" do
    page = Page.create!(title: "Admin Draft Page", status: :draft)
    sign_in_as @admin

    get page_path(page)

    assert_response :success
    assert_equal "Admin Draft Page", response.body
  end

  test "posts index shows only published posts to anonymous visitor" do
    Post.create!(
      title: "Visible Post",
      author: @author,
      status: :published,
      published_at: 1.hour.ago
    )
    Post.create!(title: "Hidden Draft", author: @author, status: :draft)

    get posts_path

    assert_response :success
    assert_includes response.body, "Visible Post"
    refute_includes response.body, "Hidden Draft"
  end

  test "published post is visible to anonymous visitor" do
    post = Post.create!(
      title: "Published Post",
      author: @author,
      status: :published,
      published_at: 1.hour.ago
    )

    get post_path(post)

    assert_response :success
    assert_equal "Published Post", response.body
  end

  test "draft post is not visible to anonymous visitor" do
    post = Post.create!(title: "Draft Post", author: @author, status: :draft)

    get post_path(post)

    assert_response :not_found
  end

  test "author can see their own draft post" do
    post = Post.create!(title: "Author Draft Post", author: @author, status: :draft)
    sign_in_as @author

    get post_path(post)

    assert_response :success
    assert_equal "Author Draft Post", response.body
  end

  test "category show renders category name" do
    category = Category.create!(name: "Announcements")

    get category_path(category)

    assert_response :success
    assert_equal "Announcements", response.body
  end
end
