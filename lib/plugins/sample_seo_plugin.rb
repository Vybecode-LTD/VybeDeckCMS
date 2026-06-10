class SampleSeoPlugin
  include VybeDeck::Plugin::Base

  self.plugin_slug        = "sample-seo"
  self.plugin_name        = "Sample SEO Plugin"
  self.plugin_version     = "1.0.0"
  self.plugin_author      = "VybeDeck Team"
  self.plugin_description = "Demonstrates the plugin hook system. Injects a generator meta tag."

  setting :inject_generator_meta,
          type:    :boolean,
          default: true,
          label:   "Inject generator meta tag",
          hint:    'Adds <meta name="generator" content="VybeDeck CMS"> to every page head.'

  setting :generator_content,
          type:    :string,
          default: "VybeDeck CMS",
          label:   "Generator value",
          hint:    "The value of the generator meta tag content attribute."

  # No outbound HTTP — allowed_hosts left empty (default).

  def self.inject_head
    record = Plugin.active_plugins.find_by(slug: plugin_slug)
    return "" unless record
    return "" unless record.setting_value("inject_generator_meta")

    content = CGI.escapeHTML(record.setting_value("generator_content").to_s.strip.presence || "VybeDeck CMS")
    %(<meta name="generator" content="#{content}">)
  end

  def self.after_post_publish(post)
    Rails.logger.info("[SampleSeoPlugin] Post published: #{post.id} — #{post.try(:title)}")
  end
end
