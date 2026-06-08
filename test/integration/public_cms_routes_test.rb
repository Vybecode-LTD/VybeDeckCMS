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
      published_at: 1.hour.ago,
      show_in_nav: true,
      position: 1
    )
    page.body = "<p>Public body copy for the published page.</p>"
    page.save!

    get page_path(page)

    assert_response :success
    assert_select "title", /Published Page/
    assert_select "main h1", "Published Page"
    assert_select "nav a", "Published Page"
    assert_includes response.body, "Public body copy for the published page."
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
    assert_select "main h1", "Admin Draft Page"
    assert_select ".status-pill", "Draft"
  end

  test "posts index shows only published posts to anonymous visitor" do
    category = Category.create!(name: "Announcements")
    visible_post = Post.create!(
      title: "Visible Post",
      author: @author,
      status: :published,
      published_at: 1.hour.ago,
      excerpt: "A public post excerpt."
    )
    visible_post.categories << category
    visible_post.body = "<p>Visible post body.</p>"
    visible_post.save!

    Post.create!(title: "Hidden Draft", author: @author, status: :draft)

    get posts_path

    assert_response :success
    assert_select "main h1", "Journal"
    assert_select "article h2", "Visible Post"
    assert_select "article a[href=?]", post_path(visible_post)
    assert_select "a[href=?]", category_path(category), text: "Announcements"
    assert_includes response.body, "Visible Post"
    assert_includes response.body, "A public post excerpt."
    refute_includes response.body, "Hidden Draft"
  end

  test "published post is visible to anonymous visitor" do
    category = Category.create!(name: "Releases")
    post = Post.create!(
      title: "Published Post",
      author: @author,
      status: :published,
      published_at: 1.hour.ago,
      excerpt: "Published post excerpt."
    )
    post.categories << category
    post.body = "<p>Published post body.</p>"
    post.save!

    get post_path(post)

    assert_response :success
    assert_select "main h1", "Published Post"
    assert_select "a[href=?]", category_path(category), text: "Releases"
    assert_includes response.body, "Published post body."
    assert_includes response.body, @author.email_address
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
    assert_select "main h1", "Author Draft Post"
    assert_select ".status-pill", "Draft"
  end

  test "category show renders category name and published posts" do
    category = Category.create!(name: "Announcements")
    visible_post = Post.create!(
      title: "Category Visible Post",
      author: @author,
      status: :published,
      published_at: 1.hour.ago,
      excerpt: "Shown on the category page."
    )
    hidden_post = Post.create!(title: "Category Draft Post", author: @author, status: :draft)
    visible_post.categories << category
    hidden_post.categories << category

    get category_path(category)

    assert_response :success
    assert_select "main h1", "Announcements"
    assert_select "article h2", "Category Visible Post"
    assert_includes response.body, "Shown on the category page."
    refute_includes response.body, "Category Draft Post"
  end
end
