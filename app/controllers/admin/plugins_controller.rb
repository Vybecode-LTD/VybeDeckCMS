module Admin
  class PluginsController < Admin::ApplicationController
    before_action :set_plugin, only: %i[activate deactivate destroy]

    def index
      authorize Plugin, :index?
      @plugins           = policy_scope(Plugin).ordered
      @loadable_plugins  = loaded_but_unregistered
    end

    def create
      authorize Plugin, :create?
      slug    = plugin_params[:slug].to_s.strip
      pc      = VybeDeck::Plugin::Registry.registered.find { |p| p.plugin_slug == slug }

      unless pc
        return redirect_to admin_plugins_path, alert: "No plugin with slug '#{slug}' is loaded in the application."
      end

      @plugin = Plugin.find_or_initialize_by(slug: slug)
      @plugin.assign_attributes(
        name:        pc.plugin_name,
        version:     pc.plugin_version,
        author:      pc.plugin_author,
        description: pc.plugin_description,
        status:      :installed
      )

      if @plugin.save
        @plugin.plugin_class&.on_install
        redirect_to admin_plugins_path, notice: "'#{@plugin.name}' installed."
      else
        redirect_to admin_plugins_path, alert: @plugin.errors.full_messages.join("; ")
      end
    end

    def activate
      authorize @plugin, :activate?
      @plugin.activate!
      redirect_to admin_plugins_path, notice: "'#{@plugin.name}' activated."
    end

    def deactivate
      authorize @plugin, :deactivate?
      @plugin.deactivate!
      redirect_to admin_plugins_path, notice: "'#{@plugin.name}' deactivated."
    end

    def destroy
      authorize @plugin
      @plugin.uninstall!
      redirect_to admin_plugins_path, notice: "'#{@plugin.name}' uninstalled."
    end

    private

    def set_plugin
      @plugin = Plugin.find(params[:id])
    end

    def plugin_params
      params.require(:plugin).permit(:slug)
    end

    def loaded_but_unregistered
      installed_slugs = Plugin.pluck(:slug)
      VybeDeck::Plugin::Registry.registered.reject { |p| installed_slugs.include?(p.plugin_slug) }
    end
  end
end
