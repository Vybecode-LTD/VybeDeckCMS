require "uri"

module VybeDeck
  module Plugin
    # Lightweight sandbox for plugin hook output and outbound HTTP.
    #
    # Two enforcement points:
    #
    #   1. HTML output validation — view hooks (inject_head, inject_footer,
    #      inject_admin_sidebar) must not emit <script> tags, javascript: URIs,
    #      or inline event-handler attributes.  The Registry calls this before
    #      adding plugin HTML to the page.
    #
    #   2. Outbound HTTP allowlist — plugins declare which external hosts they
    #      are permitted to contact via `self.allowed_hosts "api.example.com"`.
    #      Call Sandbox.validate_http!(uri, plugin_class:) inside the plugin
    #      before any Net::HTTP / Faraday / HTTParty request.  An empty
    #      allowed_hosts list means no outbound HTTP is permitted.
    #
    # This module is defence-in-depth for trusted-but-audited plugins.  It
    # does not provide full OS-level isolation.
    module Sandbox
      # Patterns that must never appear in view-hook HTML output.
      FORBIDDEN_HTML_PATTERNS = [
        /<script\b/i,
        /javascript\s*:/i,
        /\bon\w+\s*=/i,
        /data:\s*text\/html/i,
        /vbscript\s*:/i,
      ].freeze

      VIEW_HOOKS = %i[inject_head inject_footer inject_admin_sidebar].freeze

      # Validate HTML returned by a view hook.
      # Raises SandboxViolation and logs if a forbidden pattern is detected;
      # returns silently when the output is clean.
      def self.validate_html!(html, plugin_slug:, hook:)
        return if html.blank?
        FORBIDDEN_HTML_PATTERNS.each do |pattern|
          next unless html.match?(pattern)
          msg = "[PluginSandbox] #{plugin_slug}##{hook}: forbidden pattern " \
                "#{pattern.inspect} in hook output — output suppressed."
          Rails.logger.error(msg)
          raise SandboxViolation, msg
        end
      end

      # Validate an outgoing HTTP request against the plugin's allowed_hosts list.
      #
      # Usage inside a plugin:
      #
      #   def self.after_order_complete(order)
      #     VybeDeck::Plugin::Sandbox.validate_http!("https://api.example.com/notify",
      #                                              plugin_class: self)
      #     Net::HTTP.get(URI("https://api.example.com/notify?order=#{order.id}"))
      #   end
      #
      # Raises SandboxViolation when the target host is not in the allowlist.
      def self.validate_http!(uri_or_host, plugin_class:)
        host = begin
          URI.parse(uri_or_host.to_s).host
        rescue URI::InvalidURIError
          uri_or_host.to_s
        end
        allowed = Array(plugin_class.allowed_hosts)
        return if allowed.include?("*")
        unless allowed.any? { |h| host == h || host.to_s.end_with?(".#{h}") }
          raise SandboxViolation,
            "[PluginSandbox] #{plugin_class.plugin_slug}: HTTP request to " \
            "#{host.inspect} is not in allowed_hosts #{allowed.inspect}. " \
            "Add `self.allowed_hosts \"#{host}\"` to your plugin class."
        end
      end
    end
  end
end
