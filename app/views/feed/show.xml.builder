xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.rss version: "2.0",
         "xmlns:atom" => "http://www.w3.org/2005/Atom",
         "xmlns:content" => "http://purl.org/rss/1.0/modules/content/" do
  xml.channel do
    xml.title       "VybeDeck CMS"
    xml.link        root_url
    xml.description "Latest posts from VybeDeck CMS"
    xml.language    "en"
    xml.generator   "VybeDeck CMS / Rails #{Rails.version}"

    xml.tag! "atom:link",
             href: feed_url(format: :xml),
             rel:  "self",
             type: "application/rss+xml"

    if @posts.any?
      xml.lastBuildDate @posts.first.published_at.rfc2822
    end

    @posts.each do |post|
      xml.item do
        xml.title   post.title
        xml.link    post_url(post)
        xml.guid    post_url(post), isPermaLink: "true"
        xml.pubDate post.published_at.rfc2822

        xml.description(
          post.excerpt.presence ||
          post.body.to_plain_text.truncate(300, omission: "…")
        )

        xml.tag! "content:encoded" do
          xml.cdata! post.body.to_s
        end

        xml.author "#{post.author.byline}"

        post.categories.each do |category|
          xml.category category.name
        end
      end
    end
  end
end
