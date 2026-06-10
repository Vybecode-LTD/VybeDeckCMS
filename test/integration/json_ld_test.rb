require "test_helper"

# Verifies that JSON-LD structured data is rendered correctly on public pages.
class JsonLdTest < ActionDispatch::IntegrationTest
  def setup
    @admin = User.create!(
      email_address:     "jsonld_admin_#{SecureRandom.hex(4)}@test.com",
      password:          "password1234",
      display_name:      "JsonLd Admin #{SecureRandom.hex(4)}",
      role:              :admin,
      email_verified_at: Time.current
    )
  end

  # ── Post — Article + BreadcrumbList ───────────────────────────────────────

  test "post show renders Article JSON-LD with @graph" do
    post = Post.create!(
      title:        "Test Article Post",
      author:       @admin,
      status:       :published,
      published_at: 1.day.ago
    )
    get post_path(post)
    assert_response :success
    assert_select "script[type='application/ld+json']", count: 1
    json = extract_json_ld
    assert_equal "https://schema.org", json["@context"]
    graph = json["@graph"]
    assert_not_nil graph
    types = graph.map { |n| n["@type"] }
    assert_includes types, "Article"
    assert_includes types, "BreadcrumbList"
  end

  test "post Article JSON-LD includes headline and author" do
    post = Post.create!(
      title: "Headline Post", author: @admin,
      status: :published, published_at: 1.hour.ago
    )
    get post_path(post)
    json  = extract_json_ld
    article = json["@graph"].find { |n| n["@type"] == "Article" }
    assert_equal "Headline Post", article["headline"]
    assert_equal @admin.display_name, article.dig("author", "name")
  end

  test "post BreadcrumbList has 3 items including Blog" do
    post = Post.create!(
      title: "Breadcrumb Post", author: @admin,
      status: :published, published_at: 1.hour.ago
    )
    get post_path(post)
    json  = extract_json_ld
    crumbs = json["@graph"].find { |n| n["@type"] == "BreadcrumbList" }
    names = crumbs["itemListElement"].map { |e| e["name"] }
    assert_includes names, "Blog"
    assert_equal 3, names.size
  end

  # ── Product — Product + BreadcrumbList ────────────────────────────────────

  test "product show renders Product JSON-LD" do
    product = Product.create!(name: "Test Track", slug: "test-track-#{SecureRandom.hex(4)}", status: :active)
    get shop_product_path(product)
    assert_response :success
    json  = extract_json_ld
    graph = json["@graph"]
    types = graph.map { |n| n["@type"] }
    assert_includes types, "Product"
    assert_includes types, "BreadcrumbList"
  end

  test "product JSON-LD includes offers when price present" do
    product = Product.create!(name: "Priced Item", slug: "priced-#{SecureRandom.hex(4)}", status: :active)
    Price.create!(product: product, amount_cents: 999, currency: "gbp", active: true)
    get shop_product_path(product)
    json    = extract_json_ld
    product_node = json["@graph"].find { |n| n["@type"] == "Product" }
    assert_not_nil product_node["offers"]
    assert_equal "GBP", product_node.dig("offers", "priceCurrency")
    assert_equal "9.99", product_node.dig("offers", "price")
  end

  test "product BreadcrumbList has 3 items including Shop" do
    product = Product.create!(name: "Shop Crumb", slug: "shop-crumb-#{SecureRandom.hex(4)}", status: :active)
    get shop_product_path(product)
    json   = extract_json_ld
    crumbs = json["@graph"].find { |n| n["@type"] == "BreadcrumbList" }
    names  = crumbs["itemListElement"].map { |e| e["name"] }
    assert_includes names, "Shop"
    assert_equal 3, names.size
  end

  # ── Album — MusicAlbum + BreadcrumbList ───────────────────────────────────

  test "album show renders MusicAlbum JSON-LD" do
    album = Album.create!(
      title: "Test Album", artist: "Test Artist", status: :published,
      slug: "test-album-#{SecureRandom.hex(4)}"
    )
    get album_path(album)
    assert_response :success
    json  = extract_json_ld
    graph = json["@graph"]
    types = graph.map { |n| n["@type"] }
    assert_includes types, "MusicAlbum"
    assert_includes types, "BreadcrumbList"
  end

  test "album MusicAlbum JSON-LD includes byArtist" do
    album = Album.create!(
      title: "Byartist Album", artist: "The Band", status: :published,
      slug: "byartist-#{SecureRandom.hex(4)}"
    )
    get album_path(album)
    json  = extract_json_ld
    node  = json["@graph"].find { |n| n["@type"] == "MusicAlbum" }
    assert_equal "The Band", node.dig("byArtist", "name")
  end

  test "album BreadcrumbList has 3 items including Albums" do
    album = Album.create!(
      title: "Crumb Album", artist: "Artist", status: :published,
      slug: "crumb-album-#{SecureRandom.hex(4)}"
    )
    get album_path(album)
    json   = extract_json_ld
    crumbs = json["@graph"].find { |n| n["@type"] == "BreadcrumbList" }
    names  = crumbs["itemListElement"].map { |e| e["name"] }
    assert_includes names, "Albums"
    assert_equal 3, names.size
  end

  # ── Page — BreadcrumbList ─────────────────────────────────────────────────

  test "page show renders BreadcrumbList JSON-LD" do
    page = Page.create!(title: "About Us", status: :published, published_at: 1.day.ago)
    get page_path(page)
    assert_response :success
    json  = extract_json_ld
    graph = json["@graph"]
    types = graph.map { |n| n["@type"] }
    assert_includes types, "BreadcrumbList"
  end

  # ── Page with FAQ blocks — FAQPage ────────────────────────────────────────

  test "page with FAQ blocks renders FAQPage JSON-LD" do
    page = Page.create!(title: "FAQ Page", status: :published, published_at: 1.day.ago)
    FaqBlock.create!(page: page, question: "What is this?", answer: "It is a CMS.", position: 0)
    FaqBlock.create!(page: page, question: "Is it good?",   answer: "Yes.",          position: 1)

    get page_path(page)
    assert_response :success
    json  = extract_json_ld
    graph = json["@graph"]
    types = graph.map { |n| n["@type"] }
    assert_includes types, "FAQPage"
    faq_node = graph.find { |n| n["@type"] == "FAQPage" }
    questions = faq_node["mainEntity"].map { |q| q["name"] }
    assert_includes questions, "What is this?"
    assert_includes questions, "Is it good?"
  end

  test "page without FAQ blocks does not include FAQPage JSON-LD" do
    page = Page.create!(title: "No FAQ", status: :published, published_at: 1.day.ago)
    get page_path(page)
    json  = extract_json_ld
    types = json["@graph"].map { |n| n["@type"] }
    refute_includes types, "FAQPage"
  end

  # ── FAQ block admin CRUD ──────────────────────────────────────────────────

  test "admin can create FAQ block for a page" do
    page = Page.create!(title: "FAQ Admin Test", status: :published, published_at: 1.day.ago)
    post session_path, params: { email_address: @admin.email_address, password: "password1234" }

    assert_difference "FaqBlock.count", 1 do
      post admin_page_faq_blocks_path(page), params: {
        faq_block: { question: "How does it work?", answer: "Very well.", position: 0 }
      }
    end
    assert_redirected_to admin_page_faq_blocks_path(page)
    assert_equal "How does it work?", FaqBlock.last.question
  end

  test "admin can delete FAQ block" do
    page = Page.create!(title: "FAQ Delete Test", status: :published, published_at: 1.day.ago)
    faq  = FaqBlock.create!(page: page, question: "Delete me?", answer: "Yes.", position: 0)
    post session_path, params: { email_address: @admin.email_address, password: "password1234" }

    assert_difference "FaqBlock.count", -1 do
      delete admin_page_faq_block_path(page, faq)
    end
    assert_redirected_to admin_page_faq_blocks_path(page)
  end

  test "member cannot access FAQ block admin" do
    member = User.create!(
      email_address:     "faq_member_#{SecureRandom.hex(4)}@test.com",
      password:          "password1234",
      display_name:      "FaqMember #{SecureRandom.hex(4)}",
      role:              :member,
      email_verified_at: Time.current
    )
    page = Page.create!(title: "FAQ Auth Test", status: :published, published_at: 1.day.ago)
    post session_path, params: { email_address: member.email_address, password: "password1234" }
    get admin_page_faq_blocks_path(page)
    assert_redirected_to root_path
  end

  private

  def extract_json_ld
    script = css_select("script[type='application/ld+json']").first
    assert_not_nil script, "No JSON-LD script tag found"
    JSON.parse(script.children.map(&:to_s).join)
  end
end
