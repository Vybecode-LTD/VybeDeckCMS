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
        def render_hook(hook)
          active_slugs = active_plugin_slugs
          @registered
            .select { |p| active_slugs.include?(p.plugin_slug) }
            .map { |p| p.public_send(hook) rescue "" }
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
