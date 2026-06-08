require "test_helper"

class SeedsTest < ActionDispatch::IntegrationTest
  test "seeds create VybeDeck CMS content idempotently" do
    assert_difference -> { User.count }, 1 do
      load Rails.root.join("db/seeds.rb")
    end

    counts = {
      users: User.count,
      pages: Page.count,
      posts: Post.count,
      categories: Category.count
    }

    load Rails.root.join("db/seeds.rb")

    assert_equal counts[:users], User.count
    assert_equal counts[:pages], Page.count
    assert_equal counts[:posts], Post.count
    assert_equal counts[:categories], Category.count

    assert Page.friendly.find("home").published?
    assert Post.friendly.find("launch-notes").published?
    assert_equal "VybeDeck CMS", Page.friendly.find("home").meta_title
  end
end
