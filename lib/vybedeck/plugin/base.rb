module VybeDeck
  module Plugin
    # Include this module in any plugin class.
    # Override the class methods your plugin needs.
    #
    # Example:
    #   class MyPlugin
    #     include VybeDeck::Plugin::Base
    #
    #     self.plugin_slug    = "my-plugin"
    #     self.plugin_name    = "My Plugin"
    #     self.plugin_version = "1.0.0"
    #     self.plugin_author  = "Acme Ltd"
    #
    #     def self.inject_head
    #       '<meta name="generator" content="My Plugin">'
    #     end
    #   end
    module Base
      def self.included(base)
        base.extend(ClassMethods)
        VybeDeck::Plugin::Registry.register(base)
      end

      module ClassMethods
        # Required identity attributes — set via `self.attr = value` in subclass
        attr_writer :plugin_slug, :plugin_name, :plugin_version, :plugin_author, :plugin_description

        def plugin_slug;        @plugin_slug        || name.to_s.underscore.dasherize; end
        def plugin_name;        @plugin_name        || name.to_s; end
        def plugin_version;     @plugin_version     || "0.0.1"; end
        def plugin_author;      @plugin_author      || ""; end
        def plugin_description; @plugin_description || ""; end

        # Declare admin-configurable settings for this plugin.
        # Values are persisted in the Plugin#settings JSON column.
        #
        #   setting :notify_email, type: :string,  default: "",   label: "Notification email"
        #   setting :enabled,      type: :boolean, default: true, label: "Enable feature"
        #
        # Supported types: :string, :boolean, :integer
        def setting(key, type: :string, default: nil, label: nil, hint: nil)
          @declared_settings ||= []
          @declared_settings << {
            key:     key.to_s,
            type:    type,
            default: default,
            label:   label || key.to_s.humanize,
            hint:    hint
          }
        end

        def declared_settings
          @declared_settings || []
        end

        # Declare every external hostname your plugin is permitted to contact.
        # Call with arguments to set; call without to read the current list.
        #
        #   self.allowed_hosts "api.example.com", "cdn.example.com"
        #
        # Use "*" to allow all hosts (discouraged — only for fully trusted plugins).
        # An empty list (the default) means no outbound HTTP is permitted.
        def allowed_hosts(*hosts)
          if hosts.empty?
            @allowed_hosts ||= []
          else
            @allowed_hosts = hosts.flatten.map(&:to_s)
          end
        end

        # Lifecycle hooks — override as needed
        def on_install;    end
        def on_activate;   end
        def on_deactivate; end
        def on_uninstall;  end

        # View hooks — return an HTML string
        def inject_head;           ""; end
        def inject_footer;         ""; end
        def inject_admin_sidebar;  ""; end

        # Model hooks
        def after_post_publish(post);     end
        def after_order_complete(order);  end
      end
    end
  end
end
