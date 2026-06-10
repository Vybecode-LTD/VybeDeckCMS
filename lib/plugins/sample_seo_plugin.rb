class SampleSeoPlugin
  include VybeDeck::Plugin::Base

  self.plugin_slug        = "sample-seo"
  self.plugin_name        = "Sample SEO Plugin"
  self.plugin_version     = "1.0.0"
  self.plugin_author      = "VybeDeck Team"
  self.plugin_description = "Demonstrates the plugin hook system. Injects a sample meta tag."

  # No outbound HTTP — allowed_hosts left empty (default).

  def self.inject_head
    '<meta name="generator" content="VybeDeck CMS">'
  end

  def self.after_post_publish(post)
    Rails.logger.info("[SampleSeoPlugin] Post published: #{post.id} — #{post.try(:title)}")
  end
end
