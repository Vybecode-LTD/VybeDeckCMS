module VybeDeck
  module Plugin
    # Singleton registry that tracks all plugin classes loaded into the process.
    # Dispatches lifecycle and view/model hooks only to active plugins
    # (those with status :active in the Plugin table).
    class Registry
      @registered = []

      class << self
        def register(plugin_class)
          @registered << plugin_class unless @registered.include?(plugin_class)
        end

        def registered
          @registered.dup
        end

        def dispatch(hook, *args)
          active_slugs = active_plugin_slugs
          @registered.each do |plugin_class|
            next unless active_slugs.include?(plugin_class.plugin_slug)

            plugin_class.public_send(hook, *args)
          rescue StandardError => e
            Rails.logger.error("[PluginRegistry] #{plugin_class}##{hook} raised: #{e.message}")
          end
        end

        # Collect HTML string from all active plugins for a given view hook.
        # Output from each plugin is validated by the sandbox before inclusion.
        # A SandboxViolation blocks that plugin's output for this request.
        def render_hook(hook)
          active_slugs = active_plugin_slugs
          @registered
            .select { |p| active_slugs.include?(p.plugin_slug) }
            .filter_map do |p|
              html = p.public_send(hook)
              ::VybeDeck::Plugin::Sandbox.validate_html!(html, plugin_slug: p.plugin_slug, hook: hook)
              html
            rescue ::VybeDeck::Plugin::SandboxViolation
              nil
            rescue StandardError => e
              Rails.logger.error("[PluginRegistry] #{p}##{hook} raised: #{e.message}")
              nil
            end
            .join("\n")
            .html_safe
        end

        def clear!
          @registered = []
        end

        private

        def active_plugin_slugs
          ::Plugin.active_plugins.pluck(:slug)
        rescue ActiveRecord::StatementInvalid, PG::UndefinedTable
          # Table might not exist yet during db:migrate
          []
        end
      end
    end
  end
end
