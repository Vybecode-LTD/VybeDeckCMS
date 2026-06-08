require "test_helper"

class ActiveStorageVariantTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @author = User.create!(
      email_address: "variant-author-#{SecureRandom.hex(4)}@test.com",
      password: "password",
      role: :author
    )
  end

  test "page hero image variants are enqueued for background processing" do
    page = Page.create!(title: "Variant Page")

    assert_enqueued_with(job: ActiveStorage::TransformJob) do
      page.hero_image.attach(sample_png("page-hero.png"))
    end
  end

  test "post cover and gallery variants are enqueued for background processing" do
    post = Post.create!(title: "Variant Post", author: @author)

    assert_enqueued_with(job: ActiveStorage::TransformJob) do
      post.cover_image.attach(sample_png("post-cover.png"))
    end

    assert_enqueued_with(job: ActiveStorage::TransformJob) do
      post.gallery.attach(sample_png("gallery-image.png"))
    end
  end

  private

  def sample_png(filename)
    {
      io: StringIO.new(Base64.decode64(
        "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/lznjXwAAAABJRU5ErkJggg=="
      )),
      filename: filename,
      content_type: "image/png"
    }
  end
end
