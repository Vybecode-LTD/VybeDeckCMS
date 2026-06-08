require "test_helper"

class AdminContentManagementTest < ActionDispatch::IntegrationTest
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
    sign_in_as @admin
  end

  test "admin creates page with rich text body" do
    assert_difference "Page.count", 1 do
      post admin_pages_path, params: {
        page: {
          title: "Admin Page",
          body: "Managed page body",
          status: "published",
          published_at: Time.current,
          show_in_nav: "1"
        }
      }
    end

    page = Page.find_by!(title: "Admin Page")
    assert_redirected_to admin_page_path(page)
    assert_equal "Managed page body", page.body.to_plain_text
    assert page.published?
  end

  test "admin creates post with author and rich text body" do
    assert_difference "Post.count", 1 do
      post admin_posts_path, params: {
        post: {
          title: "Admin Post",
          author_id: @author.id,
          body: "Managed post body",
          excerpt: "Short summary",
          status: "draft"
        }
      }
    end

    post = Post.find_by!(title: "Admin Post")
    assert_redirected_to admin_post_path(post)
    assert_equal @author, post.author
    assert_equal "Managed post body", post.body.to_plain_text
    assert post.draft?
  end
end
